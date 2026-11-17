import Foundation
import PathKit
import XCTest

@testable import class_generator

internal final class ClassGeneratorTests: XCTestCase {

    private var temporaryDirectory: Path!

    internal override func setUpWithError() throws {
        temporaryDirectory = try Path.uniqueTemporary()
    }

    internal override func tearDownWithError() throws {
        try? temporaryDirectory.delete()
    }

    internal func testGeneratesIntoEmptyOutputDirectory() throws {
        let outputDirectory = try makeOutputDirectory()
        let generator = try makeGenerator()

        generator.outputDirectoryPath = outputDirectory
        try generator.generate()

        XCTAssertEqual(try outputDirectory.children().map(\.lastComponent).sorted(), ["Name.swift", "User.swift"])
    }

    internal func testForceReplacesExistingOutputDirectoryContents() throws {
        let outputDirectory = try makeOutputDirectory()
        try (outputDirectory + "stale.txt").write("stale")

        let generator = try makeGenerator()
        generator.outputDirectoryPath = outputDirectory
        generator.overwriteOutputDirectory = true

        try generator.generate()

        XCTAssertFalse((outputDirectory + "stale.txt").exists)
        XCTAssertTrue((outputDirectory + "User.swift").exists)
    }

    internal func testFailedGenerationLeavesOutputDirectoryUntouched() throws {
        let outputDirectory = try makeOutputDirectory()
        let staleFile = outputDirectory + "stale.txt"
        try staleFile.write("stale")

        let templateFile = temporaryDirectory + "invalid-template.swift"
        try templateFile.write("{% invalid %}")

        let generator = ClassGenerator(
            schemasDirectoryPath: try makeSchemasDirectory(),
            templateFilePath: templateFile)
        generator.outputDirectoryPath = outputDirectory
        generator.overwriteOutputDirectory = true

        XCTAssertThrowsError(try generator.generate())

        XCTAssertTrue(staleFile.exists)
        XCTAssertFalse((outputDirectory + "User.swift").exists)
        XCTAssertFalse(try temporaryDirectory.children().contains { $0.lastComponent.hasPrefix(".class-generator-") })
    }

    internal func testRejectsOutputDirectoryThatContainsInputs() throws {
        let schemasDirectory = try makeSchemasDirectory()
        let templateFile = temporaryDirectory + "template.swift"
        try templateFile.write("{{ name }}")

        let generator = ClassGenerator(
            schemasDirectoryPath: schemasDirectory,
            templateFilePath: templateFile)
        generator.outputDirectoryPath = schemasDirectory
        generator.overwriteOutputDirectory = true

        XCTAssertThrowsError(try generator.generate())
        XCTAssertTrue((schemasDirectory + "schema.json").exists)
    }

    private func makeGenerator() throws -> ClassGenerator {
        let templateFile = temporaryDirectory + "template.swift"
        try templateFile.write("{{ name }}")

        return ClassGenerator(
            schemasDirectoryPath: try makeSchemasDirectory(),
            templateFilePath: templateFile)
    }

    private func makeOutputDirectory() throws -> Path {
        let outputDirectory = temporaryDirectory + "output"
        try outputDirectory.mkdir()

        return outputDirectory
    }

    private func makeSchemasDirectory() throws -> Path {
        let schemasDirectory = temporaryDirectory + "schemas"
        try schemasDirectory.mkdir()
        try (schemasDirectory + "schema.json").write(
            """
            {
              "version": "2.1",
              "dataTypes": [
                {
                  "name": "User",
                  "properties": [
                    { "name": "name", "dataType": "Name" }
                  ]
                },
                {
                  "name": "Name",
                  "properties": []
                }
              ]
            }
            """)

        return schemasDirectory
    }

}
