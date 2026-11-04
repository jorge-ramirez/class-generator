import AppKit
import Foundation
import JavaScriptCore
import Logging
import PathKit
import Stencil

internal enum ClassGeneratorError: Error {
    case duplicateDataTypeDefined(String)
    case failedToEncodeDataType(String)
    case outputDirectoryDoesNotExist(String)
    case outputDirectoryIsNotADirectory(String)
    case outputDirectoryIsNotEmpty(String)
    case outputDirectoryWasNotSpecified
    case pluginsDirectoryDoesNotExist(String)
    case pluginsDirectoryIsEmpty(String)
    case pluginsDirectoryIsNotADirectory(String)
    case schemasDirectoryDoesNotExist(String)
    case schemasDirectoryIsEmpty(String)
    case schemasDirectoryIsNotADirectory(String)
    case templateFileDoesNotExist(String)
    case templateFileIsNotAFile(String)
    case undefinedDataTypeUsed(String)
    case unhandledDataType
}

internal class ClassGenerator {

    // MARK: - Public Properties

    internal var alphabetizeEnumValues: Bool
    internal var alphabetizeProperties: Bool
    internal var outputDirectoryPath: Path?
    internal var pluginsDirectoryPath: Path?

    // MARK: - Private Properties

    private let javaScriptContext: JSContext
    private let logger: Logger
    private var preDefinedTypes: Set<String>
    private let schemasDirectoryPath: Path
    private let templateExtension: Extension
    private let templateFilePath: Path

    // MARK: - Initialization

    internal init(schemasDirectoryPath: Path, templateFilePath: Path) {
        self.alphabetizeEnumValues = false
        self.alphabetizeProperties = false
        self.javaScriptContext = JSContext()
        self.logger = Logger(label: "class-generator")
        self.outputDirectoryPath = nil
        self.pluginsDirectoryPath = nil
        self.preDefinedTypes = []
        self.schemasDirectoryPath = schemasDirectoryPath
        self.templateExtension = Extension()
        self.templateFilePath = templateFilePath
    }

    // MARK: - Public Methods

    internal func generate() throws {
        // create the output directory if necessary
        try createOutputDirectoryIfNecessary()

        // validate the paths
        try validatePaths()

        guard let outputDirectoryPath = outputDirectoryPath else {
            throw ClassGeneratorError.outputDirectoryWasNotSpecified
        }

        // load the plugins
        try configureJavaScriptContext()
        try loadPlugins()

        // parse the data types found in the schema files
        let dataTypes = try parseAllDataTypes()

        // validate the data types which were parsed
        try validateDataTypes(dataTypes)

        // extract the template directory path, file name and file extension
        let (templateDirectoryPath, templateFileName, templateFileExtension) = templateParts()

        // create the template environment
        let templateLoader = FileSystemLoader(paths: [templateDirectoryPath])
        let templateEnvironment = Environment(loader: templateLoader, extensions: [templateExtension])

        // generate a data type file for each data type
        for dataType in dataTypes {
            let outFileName = dataType.name + "." + templateFileExtension
            let outputFilePath = outputDirectoryPath + Path(outFileName)
            logger.info("Generating output file: \(outFileName)")

            do {
                let objectDictionary = try jsonObject(for: dataType)
                let output = try templateEnvironment.renderTemplate(name: templateFileName, context: objectDictionary)
                try outputFilePath.write(output, encoding: .utf8)
            } catch let error as TemplateSyntaxError {
                logger.error("Template syntax error: \(error.description)")
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

        logger.info("Created temporary output directory: \(tempDirectory.absolute().string)")
    }

    private func parseAllDataTypes() throws -> [DataType] {
        var dataTypes: [DataType] = []

        for schemaFilePath in try schemasDirectoryPath.children() {
            guard schemaFilePath.isFile, schemaFilePath.extension == "json" else {
                logger.warning("Skipping unknown schema file type: \(schemaFilePath.lastComponent)")
                continue
            }

            logger.info("Parsing schema file: \(schemaFilePath.lastComponent)")
            let schemaFileContents: String = try schemaFilePath.read()
            let schema = try JSONDecoder().decode(Schema.self, from: Data(schemaFileContents.utf8))

            for dataType in schema.dataTypes {
                if alphabetizeProperties, let aClass = dataType as? Class {
                    aClass.alphabetizeProperties()
                }

                if alphabetizeEnumValues, let anEnum = dataType as? Enum {
                    anEnum.alphabetizeValues()
                }
            }

            dataTypes.append(contentsOf: schema.dataTypes)
        }

        return dataTypes
    }

    private func jsonObject(for dataType: DataType) throws -> [String: Any] {
        let encodedData: Data

        if let aClass = dataType as? Class {
            encodedData = try JSONEncoder().encode(aClass)
        } else if let anEnum = dataType as? Enum {
            encodedData = try JSONEncoder().encode(anEnum)
        } else {
            throw ClassGeneratorError.unhandledDataType
        }

        guard let objectDictionary = try JSONSerialization.jsonObject(with: encodedData) as? [String: Any] else {
            logger.error("Could not encode data type: \(dataType.name)")
            throw ClassGeneratorError.failedToEncodeDataType(dataType.name)
        }

        return objectDictionary
    }

    private func templateParts() -> (directoryPath: Path, fileName: String, fileExtension: String) {
        var templateDirectoryComponents = templateFilePath.components
        _ = templateDirectoryComponents.popLast()
        let templateDirectoryPath = Path(components: templateDirectoryComponents)
        let templateFileName = templateFilePath.lastComponent
        let templateExtension = templateFilePath.extension ?? "txt"

        return (directoryPath: templateDirectoryPath, fileName: templateFileName, fileExtension: templateExtension)
    }

    private func validateDataTypes(_ dataTypes: [DataType]) throws {
        var dataTypeNameToDataTypeDict: [String: DataType] = [:]

        // store the data types into the dictionary by name, throw an error when a duplicate data type name is found
        for dataType in dataTypes {
            guard dataTypeNameToDataTypeDict[dataType.name] == nil else {
                logger.error("Duplicate data type name defined: \(dataType.name)")
                throw ClassGeneratorError.duplicateDataTypeDefined(dataType.name)
            }

            dataTypeNameToDataTypeDict[dataType.name] = dataType
        }

        // ensure all of the specified types exist
        for dataType in dataTypes {
            if let aClass = dataType as? Class {
                // check all of the class' properties' types

                for property in aClass.properties {
                    if dataTypeNameToDataTypeDict[property.rawDataType] == nil
                        && !preDefinedTypes.contains(property.rawDataType)
                    {
                        logger.error("Undefined data type used: \(property.rawDataType)")
                        throw ClassGeneratorError.undefinedDataTypeUsed(property.rawDataType)
                    }
                }
            } else if let anEnum = dataType as? Enum {
                // check the enum's rawDataType

                if dataTypeNameToDataTypeDict[anEnum.dataType] == nil && !preDefinedTypes.contains(anEnum.dataType) {
                    logger.error("Undefined data type used: \(anEnum.dataType)")
                    throw ClassGeneratorError.undefinedDataTypeUsed(anEnum.dataType)
                }
            } else {
                // unhandled data type

                throw ClassGeneratorError.unhandledDataType
            }
        }
    }

    private func validateOutputDirectoryPath() throws {
        guard let outputDirectoryPath = outputDirectoryPath else {
            logger.error("No output directory was specified.")
            throw ClassGeneratorError.outputDirectoryWasNotSpecified
        }

        let absolutePath = outputDirectoryPath.absolute().string

        // ensure the output directory exists
        guard outputDirectoryPath.exists else {
            logger.error("The output directory specified does not exist: \(absolutePath)")
            throw ClassGeneratorError.outputDirectoryDoesNotExist(absolutePath)
        }

        // ensure the output directory is a directory
        guard outputDirectoryPath.isDirectory else {
            logger.error("The output directory specified is not a directory: \(absolutePath)")
            throw ClassGeneratorError.outputDirectoryIsNotADirectory(absolutePath)
        }

        // ensure the output directory is empty
        guard try outputDirectoryPath.children().isEmpty else {
            logger.error("The output directory specified is not empty: \(absolutePath)")
            throw ClassGeneratorError.outputDirectoryIsNotEmpty(absolutePath)
        }
    }

    private func validatePaths() throws {
        try validateSchemasDirectoryPath()
        try validateTemplateFilePath()
        try validateOutputDirectoryPath()
        try validatePluginsDirectoryPath()
    }

    private func validateSchemasDirectoryPath() throws {
        let absolutePath = schemasDirectoryPath.absolute().string

        // ensure the schemas directory exists
        guard schemasDirectoryPath.exists else {
            logger.error("The schemas directory specified does not exist: \(absolutePath)")
            throw ClassGeneratorError.schemasDirectoryDoesNotExist(absolutePath)
        }

        // ensure the schemas directory is a directory
        guard schemasDirectoryPath.isDirectory else {
            logger.error("The schemas directory specified is not a directory: \(absolutePath)")
            throw ClassGeneratorError.schemasDirectoryIsNotADirectory(absolutePath)
        }

        // ensure the schemas directory is not empty
        guard try !schemasDirectoryPath.children().isEmpty else {
            logger.error("The schemas directory specified is empty: \(absolutePath)")
            throw ClassGeneratorError.schemasDirectoryIsEmpty(absolutePath)
        }
    }

    private func validateTemplateFilePath() throws {
        let absolutePath = templateFilePath.absolute().string

        // ensure the template file exists
        guard templateFilePath.exists else {
            logger.error("The template file specified does not exist: \(absolutePath)")
            throw ClassGeneratorError.templateFileDoesNotExist(absolutePath)
        }

        // ensure the template file is a file
        guard templateFilePath.isFile else {
            logger.error("The template file specified is not a file: \(absolutePath)")
            throw ClassGeneratorError.templateFileIsNotAFile(absolutePath)
        }
    }

}

// MARK: - JavaScript Plugins

extension ClassGenerator {

    private func classGenLog(_ message: String) {
        logger.info("\(message)")
    }

    private func configureJavaScriptContext() throws {
        // configure an exception handler
        javaScriptContext.exceptionHandler = { [weak self] context, exception in
            if let exceptionString = exception?.toString() {
                self?.logger.error("Plugin Exception: \(exceptionString)")
                exit(1)
            }
        }

        // expose the classGenLog method to JavaScript
        let javaScriptLogHandler: @convention(block) (String) -> Void = { [weak self] message in
            self?.classGenLog(message)
        }
        let javaScriptLogHandlerObject = unsafeBitCast(javaScriptLogHandler, to: AnyObject.self)
        javaScriptContext.setObject(
            javaScriptLogHandlerObject,
            forKeyedSubscript: "classGenLog" as (NSCopying & NSObjectProtocol))
        _ = javaScriptContext.evaluateScript("classGenLog")

        // expose the registerPreDefinedTypes method to JavaScript
        let registerPreDefinedTypesHandler: @convention(block) ([String]) -> Void
        registerPreDefinedTypesHandler = { [weak self] types in
            self?.registerPreDefinedTypes(types)
        }
        let registerPreDefinedTypesHandlerObject = unsafeBitCast(registerPreDefinedTypesHandler, to: AnyObject.self)
        javaScriptContext.setObject(
            registerPreDefinedTypesHandlerObject,
            forKeyedSubscript: "registerPreDefinedTypes" as (NSCopying & NSObjectProtocol))
        _ = javaScriptContext.evaluateScript("registerPreDefinedTypes")

        // expose the registerFilter method to JavaScript
        let registerFilterHandler: @convention(block) (String, String, String) -> Void
        registerFilterHandler = { [weak self] filterName, functionName, type in
            self?.registerJavaScriptFilter(filterName: filterName, functionName: functionName, type: type)
        }
        let registerFilterHandlerObject = unsafeBitCast(registerFilterHandler, to: AnyObject.self)
        javaScriptContext.setObject(
            registerFilterHandlerObject,
            forKeyedSubscript: "registerFilter" as (NSCopying & NSObjectProtocol))
        _ = javaScriptContext.evaluateScript("registerFilter")

        // expose the registerTag method to JavaScript
        let registerTagHandler: @convention(block) (String, String) -> Void
        registerTagHandler = { [weak self] tagName, functionName in
            self?.registerJavaScriptTag(tagName: tagName, functionName: functionName)
        }
        let registerTagHandlerObject = unsafeBitCast(registerTagHandler, to: AnyObject.self)
        javaScriptContext.setObject(
            registerTagHandlerObject,
            forKeyedSubscript: "registerTag" as (NSCopying & NSObjectProtocol))
        _ = javaScriptContext.evaluateScript("registerTag")
    }

    private func convert(_ javaScriptValue: JSValue?, javaScriptType: String) -> Any? {
        switch javaScriptType {
        case "array":
            return javaScriptValue?.toArray()
        case "boolean":
            return javaScriptValue?.toBool()
        case "date":
            return javaScriptValue?.toDate()
        case "number":
            return javaScriptValue?.toNumber()
        case "object":
            return javaScriptValue?.toDictionary()
        case "string":
            return javaScriptValue?.toString()
        default:
            logger.error("Unknown JavaScript type: \(javaScriptType)")
            return javaScriptValue?.toString()
        }
    }

    private func loadPlugins() throws {
        guard let pluginsDirectoryPath = pluginsDirectoryPath else {
            return
        }

        for pluginFilePath in try pluginsDirectoryPath.children() {
            guard pluginFilePath.isFile, pluginFilePath.extension == "js" else {
                logger.warning("Skipping unknown plugin file type: \(pluginFilePath.lastComponent)")
                continue
            }

            logger.info("Loading plugin: \(pluginFilePath.lastComponent)")
            let pluginFileContents: String = try pluginFilePath.read()
            _ = javaScriptContext.evaluateScript(pluginFileContents)
        }
    }

    private func registerJavaScriptFilter(filterName: String, functionName: String, type: String) {
        logger.info("Registering JavaScript filter: \(filterName)")

        templateExtension.registerFilter(filterName) { [weak self] value in
            guard let javaScriptFunction = self?.javaScriptContext.objectForKeyedSubscript(functionName) else {
                self?.logger.error("Could not find JavaScript filter function: \(functionName)")
                throw TemplateSyntaxError("Could not find JavaScript filter function: " + functionName)
            }

            var args: [Any] = []
            if let value = value {
                args.append(value)
            }

            let javaScriptValue = javaScriptFunction.call(withArguments: args)
            return self?.convert(javaScriptValue, javaScriptType: type)
        }
    }

    private func registerJavaScriptTag(tagName: String, functionName: String) {
        logger.info("Registering JavaScript tag: \(tagName)")

        templateExtension.registerSimpleTag(tagName) { [weak self] context in
            guard let javaScriptFunction = self?.javaScriptContext.objectForKeyedSubscript(functionName) else {
                self?.logger.error("Could not find JavaScript tag function: \(functionName)")
                throw TemplateSyntaxError("Could not find JavaScript tag function: " + functionName)
            }

            guard let javaScriptValue = javaScriptFunction.call(withArguments: [context.flatten()]),
                let value = javaScriptValue.toString()
            else {
                throw TemplateSyntaxError("Error while calling JavaScript tag function: " + functionName)
            }

            return value
        }
    }

    private func registerPreDefinedTypes(_ typeNames: [String]) {
        logger.info("Registering pre-defined types: \(typeNames)")
        preDefinedTypes = Set<String>(typeNames)
    }

    private func validatePluginsDirectoryPath() throws {
        guard let pluginsDirectoryPath = pluginsDirectoryPath else {
            return
        }

        let absolutePath = pluginsDirectoryPath.absolute().string

        // ensure the plugins directory exists
        guard pluginsDirectoryPath.exists else {
            logger.error("The plugin directory specified does not exist: \(absolutePath)")
            throw ClassGeneratorError.pluginsDirectoryDoesNotExist(absolutePath)
        }

        // ensure the plugins directory is a directory
        guard pluginsDirectoryPath.isDirectory else {
            logger.error("The plugin directory specified is not a directory: \(absolutePath)")
            throw ClassGeneratorError.pluginsDirectoryIsNotADirectory(absolutePath)
        }

        // ensure the plugins directory is not empty
        guard try !pluginsDirectoryPath.children().isEmpty else {
            logger.error("The plugin directory specified is empty: \(absolutePath)")
            throw ClassGeneratorError.pluginsDirectoryIsEmpty(absolutePath)
        }
    }

}
