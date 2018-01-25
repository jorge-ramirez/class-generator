import Foundation
import SwiftCLI

internal class GenerateCommand: SwiftCLI.Command {

    // MARK: - Private Properties

    // parameters, ordered by how they will be parsed
    private let inputDirectoryPath = Parameter()
    private let outputDirectoryPath = Parameter()
    private let templateFilePath = Parameter()

    // options
    private let alphabetizeProperties = Flag("--alphabetize-properties", description: "The generated properties are listed alphabetical order.")
    private let removeOutputFiles = Flag("--remove-output-files", description: "Removes any existing output files.")

    // MARK: - Command Protocol

    let name = "generate"
    let shortDescription = "Generates an output file for each class found in the input directory files, using the given template."

    func execute() throws {
        do {
            let generator = ClassGenerator(inputDirectory: inputDirectoryPath.value,
                                           outputDirectory: outputDirectoryPath.value,
                                           templateFile: templateFilePath.value)

            generator.alphabetizeProperties = alphabetizeProperties.value
            generator.removeOutputFiles = removeOutputFiles.value

            try generator.generate()
        } catch ClassGeneratorError.inputDirectoryDoesNotExist {
            NSLog("The input directory does not exist.")
        } catch ClassGeneratorError.inputDirectoryIsEmpty {
            NSLog("The input directory is empty.")
        } catch ClassGeneratorError.inputDirectoryIsNotADirectory {
            NSLog("The input directory is not a directory.")
        } catch ClassGeneratorError.outputDirectoryIsNotADirectory {
            NSLog("The output directory is not a directory.")
        } catch ClassGeneratorError.outputDirectoryIsNotEmpty {
            NSLog("The output directory is not empty.")
        } catch ClassGeneratorError.outputDirectoryIsNotWritable {
            NSLog("The output directory is not writable.")
        } catch ClassGeneratorError.templateFileDoesNotExist {
            NSLog("The template file does not exist.")
        } catch ClassGeneratorError.templateFileIsNotAFile {
            NSLog("The template file is not a file.")
        } catch ClassGeneratorError.duplicateClass(let className) {
            NSLog("Duplicate class name defined: \"\(className)\".")
        } catch ClassGeneratorError.undefinedClass(let className) {
            NSLog("Undefined class name used: \"\(className)\".")
        }
    }
}
