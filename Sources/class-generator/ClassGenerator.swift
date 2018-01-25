import Foundation
import ObjectMapper
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
    case duplicateClass(String)
    case undefinedClass(String)
}

internal class ClassGenerator {

    // MARK: - Private Properties

    private let inputDirectoryPath: Path
    private let outputDirectoryPath: Path
    private let removeOutputFiles: Bool
    private let templateFilePath: Path

    // MARK: - Initialization

    init(inputDirectory: String, outputDirectory: String, templateFile: String, removeOutputFiles: Bool?) {
        self.inputDirectoryPath = Path(inputDirectory)
        self.outputDirectoryPath = Path(outputDirectory)
        self.removeOutputFiles = removeOutputFiles ?? false
        self.templateFilePath = Path(templateFile)
    }

    // MARK: - Public Methods

    func generate() throws {
        // validate the paths
		try validatePaths()

        // parse the classes found in the input files
        let classes = try parseAllClasses()

        // validate the classes which were parsed
        try validateClasses(classes)

        // extract the template directory path and template file name
        let (templateDirectoryPath, templateFileName) = templateDirectoryPathAndFileName()

        // create the template extension and environment
        let templateExtensions = createTemplateExtensions()
        let templateEnvironment = Environment(loader: FileSystemLoader(paths: [templateDirectoryPath]),
                                              extensions: templateExtensions)

        // generate a class file for each class
        try classes.forEach {
            let objectDictionary = Mapper().toJSON($0)
            let output = try templateEnvironment.renderTemplate(name: templateFileName, context: objectDictionary)
            let outputFilePath = outputDirectoryPath + Path($0.name + ".swift")
            try outputFilePath.write(output, encoding: .utf8)
        }
    }

    // MARK: - Private Methods

    private func addSwiftPropertyDeclarationFilter(to templateExtension: Extension) {
        templateExtension.registerFilter("swiftPropertyDeclaration") { (value: Any?) in
            guard let propertyJSON = value as? [String: Any],
                let property = (try? Mapper<Property>().map(JSON: propertyJSON)) else {
                return value
            }

            var declaration = "\(property.name): "

            if property.isArray {
                declaration += "["
            }

            switch property.type {
            case .bool:
                declaration += "Bool"
            case let .custom(customType):
                declaration += customType
            case .decimal:
                declaration += "Double"
            case .double:
                declaration += "Double"
            case .int:
                declaration += "Int"
            case .long:
                declaration += "Int"
            case .string:
                declaration += "String"
            }

            if property.isArray {
                declaration += "]"
            }

            if !property.isRequired {
                declaration += "?"
            }

            return declaration
        }
    }

    private func createTemplateExtensions() -> [Extension] {
        let templateExtension = Extension()
        addSwiftPropertyDeclarationFilter(to: templateExtension)

        return [templateExtension]
    }

    private func parseAllClasses() throws -> [Class] {
        var classes: [Class] = []

        try inputDirectoryPath.children().forEach { inputFile in
            guard inputFile.isFile, inputFile.extension == "json" else {
                NSLog("Skipping input file: \(inputFile.lastComponent)")
                return
            }

            let inputFileContents: String = try inputFile.read()
            let inputFileClasses = try Mapper<Class>().mapArray(JSONString: inputFileContents)
            classes.append(contentsOf: inputFileClasses)
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
                throw ClassGeneratorError.duplicateClass($0.name)
            }

            classNameToClassDict[$0.name] = $0
        }

        // ensure all of the specified property types exist
        try classes.forEach {
            try $0.properties.forEach {
                switch $0.type {
                case .bool, .decimal, .double, .int, .long, .string:
                    // primitive type, no need to validate
                    break
                case let .custom(customTypeName):
                    // ensure the custom type name has been defined
                    if classNameToClassDict[customTypeName] == nil {
                        throw ClassGeneratorError.undefinedClass(customTypeName)
                    }
                }
            }
        }
    }

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

            let outputFiles = try outputDirectoryPath.children()

            if !outputFiles.isEmpty {
                // the output directory is not empty

                if removeOutputFiles {
                    // delete all of the output files in the output file directory
                    try outputFiles.forEach {
                        try $0.delete()
                    }
                } else {
                    throw ClassGeneratorError.outputDirectoryIsNotEmpty
                }
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
