import Foundation
import LoggerAPI
import PathKit
import SwiftCLI

internal class GenerateCommand: SwiftCLI.Command {

    // MARK: - Private Properties

    // parameters, ordered by how they will be parsed
    private let schemasDirectoryPath: Parameter = Parameter()
    private let templateFilePath: Parameter = Parameter()

    // options
    private let alphabetizeEnumValues: Flag = Flag("--alphabetize-enum-values",
        description: "The generated enum values will be listed alphabetical order.")
    private let alphabetizeProperties: Flag = Flag("--alphabetize-properties",
        description: "The generated class properties will be listed alphabetical order.")
    private let outputDirectoryPath: Key<String> = Key<String>("--output-directory-path",
        description: "The output directory where all generated files will be saved to.")
    private let pluginsDirectoryPath: Key<String> = Key<String>("--plugins-directory-path",
        description: "A directory containing plugins which will be loaded at runtime.")

    // MARK: - Command Protocol

    internal let name: String = "generate"
    internal let shortDescription: String = "Generates an output file for each data type found in the specified schemas."

    internal func execute() throws {
        let generator = ClassGenerator(schemasDirectoryPath: Path(schemasDirectoryPath.value),
                                       templateFilePath: Path(templateFilePath.value))

        generator.alphabetizeEnumValues = alphabetizeEnumValues.value
        generator.alphabetizeProperties = alphabetizeProperties.value

        if let outputDirectoryPath = outputDirectoryPath.value {
            generator.outputDirectoryPath = Path(outputDirectoryPath)
        }

        if let pluginsDirectoryPath = pluginsDirectoryPath.value {
            generator.pluginsDirectoryPath = Path(pluginsDirectoryPath)
        }

        try generator.generate()
    }

}
