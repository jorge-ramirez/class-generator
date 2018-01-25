import Foundation
import PathKit
import Stencil

internal enum ClassGeneratorError: Error {
    case inputDirectoryDoesNotExist
    case inputDirectoryIsEmpty
    case inputDirectoryIsNotADirectory
    case outputDirectoryIsNotADirectory
    case outputDirectoryIsNotEmpty
    case outputDirectoryIsNotWritable
    case templateFileDoesNotExist
    case templateFileIsNotAFile
}

internal class ClassGenerator {

    // MARK: - Private Properties

    private let inputDirectoryPath: Path
    private let outputDirectoryPath: Path
    private let templateFilePath: Path

    // MARK: - Initialization

    init(inputDirectory: String, outputDirectory: String, templateFile: String) throws {
        inputDirectoryPath = Path(inputDirectory)
        outputDirectoryPath = Path(outputDirectory)
        templateFilePath = Path(templateFile)

        try validatePaths()
    }

    // MARK: - Public Methods

    func generate() throws {
        var templatesDirectoryComponents = templateFilePath.components
        _ = templatesDirectoryComponents.popLast()
        let templatesDirectoryPath = Path(components: templatesDirectoryComponents)
        let templateFileName = templateFilePath.lastComponent

        let environment = Environment(loader: FileSystemLoader(paths: [templatesDirectoryPath]))
        let rendered = try environment.renderTemplate(name: templateFileName, context: [:])
        NSLog("\(rendered)")
    }

    // MARK: - Private Methods

    private func validateInputDirectoryPath() throws {
        // ensure the input directory exists
        guard inputDirectoryPath.exists else {
            throw ClassGeneratorError.inputDirectoryDoesNotExist
        }

        // ensure the input directory is a directory
        guard inputDirectoryPath.isDirectory else {
            throw ClassGeneratorError.inputDirectoryIsNotADirectory
        }

        // ensure the input directory is not empty
        guard try !inputDirectoryPath.children().isEmpty else {
            throw ClassGeneratorError.inputDirectoryIsEmpty
        }
    }

    private func validateOutputDirectoryPath() throws {
        // if the output directory exists
        if outputDirectoryPath.exists {
            // ensure the output directory is a directory
            guard outputDirectoryPath.isDirectory else {
                throw ClassGeneratorError.outputDirectoryIsNotADirectory
            }

            // ensure the output directory is empty
            guard try outputDirectoryPath.children().isEmpty else {
                throw ClassGeneratorError.outputDirectoryIsNotEmpty
            }
        } else {
            // create the output directory
            try outputDirectoryPath.mkpath()
        }
    }

    private func validatePaths() throws {
        try validateInputDirectoryPath()
        try validateOutputDirectoryPath()
        try validateTemplateFilePath()
    }

    private func validateTemplateFilePath() throws {
        // ensure the template file exists
        guard templateFilePath.exists else {
            throw ClassGeneratorError.templateFileDoesNotExist
        }

        // ensure the template file is a file
        guard templateFilePath.isFile else {
            throw ClassGeneratorError.templateFileIsNotAFile
        }
    }

}
