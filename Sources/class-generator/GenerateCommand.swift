import Foundation
import LoggerAPI
import PathKit
import SwiftCLI

internal class GenerateCommand: SwiftCLI.Command {

    // MARK: - Private Properties

    // parameters, ordered by how they will be parsed
    private let schemasDirectoryPath = Parameter()
    private let templateFilePath = Parameter()

    // options
    private let alphabetizeProperties = Flag("--alphabetize-properties", description: "The generated properties will be listed alphabetical order.")
    private let outputDirectoryPath = Key<String>("--output-directory-path", description: "The output directory where all generated files will be saved to.  A temporary directory will be used if none is provided.")
    private let pluginsDirectoryPath = Key<String>("--plugins-directory-path", description: "A directory containing plugins which will be loaded at runtime.")

    // MARK: - Command Protocol

    let name = "generate"
    let shortDescription = "Generates an output file for each class definition found in the specified schemas, using the specified template."

    func execute() throws {
        let generator = ClassGenerator(schemasDirectoryPath: Path(schemasDirectoryPath.value),
                                       templateFilePath: Path(templateFilePath.value))

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
