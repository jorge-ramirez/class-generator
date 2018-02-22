import AppKit
import Foundation
import JavaScriptCore
import LoggerAPI
import ObjectMapper
import PathKit
import Stencil

// swiftlint:disable file_length

internal enum ClassGeneratorError: Error {
    case duplicateClassDefined(String)
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
    case undefinedClassUsed(String)
}

internal class ClassGenerator {

    // MARK: - Public Properties

    internal var alphabetizeProperties: Bool
    internal var outputDirectoryPath: Path?
    internal var pluginsDirectoryPath: Path?

    // MARK: - Private Properties

    private let javaScriptContext: JSContext
    private var preDefinedTypes: Set<String>
    private let schemasDirectoryPath: Path
    private let templateExtension: Extension
    private let templateFilePath: Path

    // MARK: - Initialization

    internal init(schemasDirectoryPath: Path, templateFilePath: Path) {
        self.alphabetizeProperties = false
        self.javaScriptContext = JSContext()
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

        // parse the classes found in the schema files
        let classes = try parseAllClasses()

        // validate the classes which were parsed
        try validateClasses(classes)

        // extract the template directory path and template file name
        let (templateDirectoryPath, templateFileName) = templateDirectoryPathAndFileName()

        // create the template environment
        let templateLoader = FileSystemLoader(paths: [templateDirectoryPath])
        let templateEnvironment = Environment(loader: templateLoader, extensions: [templateExtension])

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

        try schemasDirectoryPath.children().forEach { schemaFilePath in
            guard schemaFilePath.isFile, schemaFilePath.extension == "json" else {
                Log.warning("Skipping unknown schema file type: \(schemaFilePath.lastComponent)")
                return
            }

            Log.info("Parsing schema file: " + schemaFilePath.lastComponent)
            let schemaFileContents: String = try schemaFilePath.read()
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
        try validateSchemasDirectoryPath()
        try validateTemplateFilePath()
        try validateOutputDirectoryPath()
        try validatePluginsDirectoryPath()
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

// MARK: - JavaScript Plugins

extension ClassGenerator {

    private func classGenLog(_ message: String) {
        Log.info(message)
    }

    private func configureJavaScriptContext() throws {
        // configure an exception handler
        javaScriptContext.exceptionHandler = { context, exception in
            if let exceptionString = exception?.toString() {
                Log.error("Plugin Exception: " + exceptionString)
                exit(1)
            }
        }

        // expose the classGenLog method to JavaScript
        let javaScriptLogHandler: @convention(block) (String) -> Void = { [weak self] message in
            self?.classGenLog(message)
        }
        let javaScriptLogHandlerObject = unsafeBitCast(javaScriptLogHandler, to: AnyObject.self)
        javaScriptContext.setObject(javaScriptLogHandlerObject,
                                    forKeyedSubscript: "classGenLog" as (NSCopying & NSObjectProtocol)!) // swiftlint:disable:this force_unwrapping line_length
        _ = javaScriptContext.evaluateScript("classGenLog")

        // expose the registerPreDefinedTypes method to JavaScript
        let registerPreDefinedTypesHandler: @convention(block) ([String]) -> Void
        registerPreDefinedTypesHandler = { [weak self] types in
            self?.registerPreDefinedTypes(types)
        }
        let registerPreDefinedTypesHandlerObject = unsafeBitCast(registerPreDefinedTypesHandler, to: AnyObject.self)
        javaScriptContext.setObject(registerPreDefinedTypesHandlerObject,
                                    forKeyedSubscript: "registerPreDefinedTypes" as (NSCopying & NSObjectProtocol)!) // swiftlint:disable:this force_unwrapping line_length
        _ = javaScriptContext.evaluateScript("registerPreDefinedTypes")

        // expose the registerFilter method to JavaScript
        let registerFilterHandler: @convention(block) (String, String, String) -> Void
        registerFilterHandler = { [weak self] filterName, functionName, type in
            self?.registerJavaScriptFilter(filterName: filterName, functionName: functionName, type: type)
        }
        let registerFilterHandlerObject = unsafeBitCast(registerFilterHandler, to: AnyObject.self)
        javaScriptContext.setObject(registerFilterHandlerObject,
                                    forKeyedSubscript: "registerFilter" as (NSCopying & NSObjectProtocol)!) // swiftlint:disable:this force_unwrapping line_length
        _ = javaScriptContext.evaluateScript("registerFilter")

        // expose the registerTag method to JavaScript
        let registerTagHandler: @convention(block) (String, String) -> Void
        registerTagHandler = { [weak self] tagName, functionName in
            self?.registerJavaScriptTag(tagName: tagName, functionName: functionName)
        }
        let registerTagHandlerObject = unsafeBitCast(registerTagHandler, to: AnyObject.self)
        javaScriptContext.setObject(registerTagHandlerObject,
                                    forKeyedSubscript: "registerTag" as (NSCopying & NSObjectProtocol)!) // swiftlint:disable:this force_unwrapping line_length
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
            Log.error("Unknown JavaScript type: " + javaScriptType)
            return javaScriptValue?.toString()
        }
    }

    private func loadPlugins() throws {
        guard let pluginsDirectoryPath = pluginsDirectoryPath else {
            return
        }

        try pluginsDirectoryPath.children().forEach { pluginFilePath in
            guard pluginFilePath.isFile, pluginFilePath.extension == "js" else {
                Log.warning("Skipping unknown plugin file type: \(pluginFilePath.lastComponent)")
                return
            }

            Log.info("Loading plugin: " + pluginFilePath.lastComponent)
            let pluginFileContents: String = try pluginFilePath.read()
            _ = javaScriptContext.evaluateScript(pluginFileContents)
        }
    }

    private func registerJavaScriptFilter(filterName: String, functionName: String, type: String) {
        Log.info("Registering JavaScript filter: " + filterName)

        templateExtension.registerFilter(filterName) { [weak self] value in
            guard let javaScriptFunction = self?.javaScriptContext.objectForKeyedSubscript(functionName) else {
                Log.error("Could not find JavaScript filter function: " + functionName)
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
        Log.info("Registering JavaScript tag: " + tagName)

        templateExtension.registerSimpleTag(tagName) { [weak self] context in
            guard let javaScriptFunction = self?.javaScriptContext.objectForKeyedSubscript(functionName) else {
                Log.error("Could not find JavaScript tag function: " + functionName)
                throw TemplateSyntaxError("Could not find JavaScript tag function: " + functionName)
            }

            guard let javaScriptValue = javaScriptFunction.call(withArguments: [context.flatten()]),
                    let value = javaScriptValue.toString() else {
                throw TemplateSyntaxError("Error while calling JavaScript tag function: " + functionName)
            }

            return value
        }
    }

    private func registerPreDefinedTypes(_ typeNames: [String]) {
        Log.info("Registering pre-defined types: \(typeNames)")
        preDefinedTypes = Set<String>(typeNames)
    }

    private func validatePluginsDirectoryPath() throws {
        guard let pluginsDirectoryPath = pluginsDirectoryPath else {
            return
        }

        let absolutePath = pluginsDirectoryPath.absolute().string

        // ensure the plugins directory exists
        guard pluginsDirectoryPath.exists else {
            Log.error("The plugin directory specified does not exist: " + absolutePath)
            throw ClassGeneratorError.pluginsDirectoryDoesNotExist(absolutePath)
        }

        // ensure the plugins directory is a directory
        guard pluginsDirectoryPath.isDirectory else {
            Log.error("The plugin directory specified is not a directory: " + absolutePath)
            throw ClassGeneratorError.pluginsDirectoryIsNotADirectory(absolutePath)
        }

        // ensure the plugins directory is not empty
        guard try !pluginsDirectoryPath.children().isEmpty else {
            Log.error("The plugin directory specified is empty: " + absolutePath)
            throw ClassGeneratorError.pluginsDirectoryIsEmpty(absolutePath)
        }
    }

}
