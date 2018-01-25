import SwiftCLI

internal class GenerateCommand: SwiftCLI.Command {

    // MARK: - Private Properties

    // parameters, ordered by how they will be parsed
    private let inputDirectoryPath = Parameter()
    private let outputDirectoryPath = Parameter()
    private let templateFilePath = Parameter()

    // MARK: - Command Protocol

    let name = "generate"
    let shortDescription = "Generates an output file for each class found in the input files directory, using the given template."

    func execute() throws {
        do {
            let generator = try ClassGenerator(inputDirectory: inputDirectoryPath.value,
                                               outputDirectory: outputDirectoryPath.value,
                                               templateFile: templateFilePath.value)
            try generator.generate()
        } catch {
            let message = self.message(for: error)
            print("Error: \(message)")
        }
    }

    private func message(for error: Error) -> String {
        let message: String

        switch error {
        case ClassGeneratorError.inputDirectoryDoesNotExist:
            message = "The input directory does not exist"
        case ClassGeneratorError.inputDirectoryIsEmpty:
            message = "The input directory is empty"
        case ClassGeneratorError.inputDirectoryIsNotADirectory:
            message = "The input directory is not a directory"
        case ClassGeneratorError.outputDirectoryIsNotADirectory:
            message = "The output directory is not a directory"
        case ClassGeneratorError.outputDirectoryIsNotEmpty:
            message = "The output directory is not empty"
        case ClassGeneratorError.outputDirectoryIsNotWritable:
            message = "The output directory is not writable"
        case ClassGeneratorError.templateFileDoesNotExist:
            message = "The template file does not exist"
        case ClassGeneratorError.templateFileIsNotAFile:
            message = "The template file is not a file"
        default:
            message = "Unknown error"
        }

        return message
    }
}
