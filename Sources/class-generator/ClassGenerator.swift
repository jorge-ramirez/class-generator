import AppKit
import Foundation
import LoggerAPI
import ObjectMapper
import PathKit
import Stencil

internal enum ClassGeneratorError: Error {
    case duplicateClassDefined(String)
    case outputDirectoryDoesNotExist(String)
    case outputDirectoryIsNotADirectory(String)
    case outputDirectoryIsNotEmpty(String)
    case outputDirectoryWasNotSpecified
    case schemasDirectoryDoesNotExist(String)
    case schemasDirectoryIsEmpty(String)
    case schemasDirectoryIsNotADirectory(String)
    case templateFileDoesNotExist(String)
    case templateFileIsNotAFile(String)
    case undefinedClassUsed(String)
}

internal class ClassGenerator {

    // MARK: - Public Properties

    var alphabetizeProperties: Bool
    var outputDirectoryPath: Path?
    var preDefinedTypes: Set<String>

    // MARK: - Private Properties

    private let schemasDirectoryPath: Path
    private let templateFilePath: Path

    // MARK: - Initialization

    init(schemasDirectoryPath: Path, templateFilePath: Path) {
        self.alphabetizeProperties = false
        self.schemasDirectoryPath = schemasDirectoryPath
        self.outputDirectoryPath = nil
        self.preDefinedTypes = ["Bool", "Date", "Decimal", "Double", "Float", "Int", "Long", "String"]
        self.templateFilePath = templateFilePath
    }

    // MARK: - Public Methods

    func generate() throws {
        // create the output directory if necessary
        try createOutputDirectoryIfNecessary()

        // validate the paths
		try validatePaths()

        guard let outputDirectoryPath = outputDirectoryPath else {
            throw ClassGeneratorError.outputDirectoryWasNotSpecified
        }

        // parse the classes found in the schema files
        let classes = try parseAllClasses()

        // validate the classes which were parsed
        try validateClasses(classes)

        // extract the template directory path and template file name
        let (templateDirectoryPath, templateFileName) = templateDirectoryPathAndFileName()

        // create the template environment
        let templateEnvironment = Environment(loader: FileSystemLoader(paths: [templateDirectoryPath]))

        // generate a class file for each class
        try classes.forEach {
            let outputFilePath = outputDirectoryPath + Path($0.name + ".swift")
            Log.info("Generating output file: " + outputFilePath.lastComponent)

            do {
                let objectDictionary = Mapper().toJSON($0)
                let output = try templateEnvironment.renderTemplate(name: templateFileName, context: objectDictionary)
                try outputFilePath.write(output, encoding: .utf8)
            } catch let error as TemplateSyntaxError {
                Log.error("Template syntax error: " + error.description)
                throw error
            }
        }

        // open the output directory
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: outputDirectoryPath.absolute().string)
    }

    // MARK: - Private Methods

    private func createOutputDirectoryIfNecessary() throws {
        guard outputDirectoryPath == nil else {
            return
        }

        let tempDirectory = try Path.uniqueTemporary()
        outputDirectoryPath = tempDirectory

        Log.info("Created temporary output directory: " + tempDirectory.absolute().string)
    }

    private func parseAllClasses() throws -> [Class] {
        var classes: [Class] = []
        let context = MappingContext(alphabetizeProperties: alphabetizeProperties)
        let mapper = Mapper<Class>(context: context)

        try schemasDirectoryPath.children().forEach { schemaFile in
            guard schemaFile.isFile, schemaFile.extension == "json" else {
                Log.warning("Skipping unknown schema file type: \(schemaFile.lastComponent)")
                return
            }

            Log.info("Parsing schema file: " + schemaFile.lastComponent)
            let schemaFileContents: String = try schemaFile.read()
            let schemaFileClasses = try mapper.mapArray(JSONString: schemaFileContents)
            classes.append(contentsOf: schemaFileClasses)
        }

        return classes
    }

    private func templateDirectoryPathAndFileName() -> (templateDirectoryPath: Path, templateFileName: String) {
        var templateDirectoryComponents = templateFilePath.components
        _ = templateDirectoryComponents.popLast()
        let templateDirectoryPath = Path(components: templateDirectoryComponents)

        let templateFileName = templateFilePath.lastComponent

        return (templateDirectoryPath: templateDirectoryPath, templateFileName: templateFileName)
    }

    private func validateClasses(_ classes: [Class]) throws {
        var classNameToClassDict: [String: Class] = [:]

        // store the classes into the dictionary by name, throw an error when a duplicate class is found
        try classes.forEach {
            guard classNameToClassDict[$0.name] == nil else {
                Log.error("Duplicate class name defined: " + $0.name)
                throw ClassGeneratorError.duplicateClassDefined($0.name)
            }

            classNameToClassDict[$0.name] = $0
        }

        // ensure all of the specified property types exist
        try classes.forEach {
            try $0.properties.forEach {
                if classNameToClassDict[$0.rawType] == nil && !preDefinedTypes.contains($0.rawType) {
                    Log.error("Undefined class name used: " + $0.rawType)
                    throw ClassGeneratorError.undefinedClassUsed($0.rawType)
                }
            }
        }
    }

    private func validateOutputDirectoryPath() throws {
        guard let outputDirectoryPath = outputDirectoryPath else {
            Log.error("No output directory was specified.")
            throw ClassGeneratorError.outputDirectoryWasNotSpecified
        }

        let absolutePath = outputDirectoryPath.absolute().string

        // ensure the output directory exists
        guard outputDirectoryPath.exists else {
            Log.error("The output directory specified does not exist: " + absolutePath)
            throw ClassGeneratorError.outputDirectoryDoesNotExist(absolutePath)
        }

        // ensure the output directory is a directory
        guard outputDirectoryPath.isDirectory else {
            Log.error("The output directory specified is not a directory: " + absolutePath)
            throw ClassGeneratorError.outputDirectoryIsNotADirectory(absolutePath)
        }

        // ensure the output directory is empty
        guard try outputDirectoryPath.children().isEmpty else {
            Log.error("The output directory specified is not empty: " + absolutePath)
            throw ClassGeneratorError.outputDirectoryIsNotEmpty(absolutePath)
        }
    }

    private func validatePaths() throws {
        try validateOutputDirectoryPath()
        try validateSchemasDirectoryPath()
        try validateTemplateFilePath()
    }

    private func validateSchemasDirectoryPath() throws {
        let absolutePath = schemasDirectoryPath.absolute().string

        // ensure the schemas directory exists
        guard schemasDirectoryPath.exists else {
            Log.error("The schemas directory specified does not exist: " + absolutePath)
            throw ClassGeneratorError.schemasDirectoryDoesNotExist(absolutePath)
        }

        // ensure the schemas directory is a directory
        guard schemasDirectoryPath.isDirectory else {
            Log.error("The schemas directory specified is not a directory: " + absolutePath)
            throw ClassGeneratorError.schemasDirectoryIsNotADirectory(absolutePath)
        }

        // ensure the schemas directory is not empty
        guard try !schemasDirectoryPath.children().isEmpty else {
            Log.error("The schemas directory specified is empty: " + absolutePath)
            throw ClassGeneratorError.schemasDirectoryIsEmpty(absolutePath)
        }
    }

    private func validateTemplateFilePath() throws {
        let absolutePath = templateFilePath.absolute().string

        // ensure the template file exists
        guard templateFilePath.exists else {
            Log.error("The template file specified does not exist: " + absolutePath)
            throw ClassGeneratorError.templateFileDoesNotExist(absolutePath)
        }

        // ensure the template file is a file
        guard templateFilePath.isFile else {
            Log.error("The template file specified is not a file: " + absolutePath)
            throw ClassGeneratorError.templateFileIsNotAFile(absolutePath)
        }
    }

}
