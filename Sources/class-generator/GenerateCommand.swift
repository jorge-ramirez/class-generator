import ArgumentParser
import Foundation
import LoggerAPI
import PathKit

internal struct GenerateCommand: ParsableCommand {

    // MARK: - Command Configuration

    internal static let configuration: CommandConfiguration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generates an output file for each data type found in the specified schemas.")

    // MARK: - Arguments

    @Argument(help: "The directory containing the JSON schema files.")
    internal var schemasDirectoryPath: String

    @Argument(help: "The template file used to generate the output files.")
    internal var templateFilePath: String

    // MARK: - Options

    @Flag(name: .customLong("alphabetize-enum-values"),
          help: "The generated enum values will be listed alphabetical order.")
    internal var alphabetizeEnumValues: Bool = false

    @Flag(name: .customLong("alphabetize-properties"),
          help: "The generated class properties will be listed alphabetical order.")
    internal var alphabetizeProperties: Bool = false

    @Option(name: .customLong("output-directory-path"),
            help: "The output directory where all generated files will be saved to.")
    internal var outputDirectoryPath: String?

    @Option(name: .customLong("plugins-directory-path"),
            help: "A directory containing plugins which will be loaded at runtime.")
    internal var pluginsDirectoryPath: String?

    // MARK: - Command

    internal mutating func run() throws {
        let generator = ClassGenerator(schemasDirectoryPath: Path(schemasDirectoryPath),
                                       templateFilePath: Path(templateFilePath))

        generator.alphabetizeEnumValues = alphabetizeEnumValues
        generator.alphabetizeProperties = alphabetizeProperties

        if let outputDirectoryPath = outputDirectoryPath {
            generator.outputDirectoryPath = Path(outputDirectoryPath)
        }

        if let pluginsDirectoryPath = pluginsDirectoryPath {
            generator.pluginsDirectoryPath = Path(pluginsDirectoryPath)
        }

        try generator.generate()
    }

}
