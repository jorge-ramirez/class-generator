import HeliumLogger
import LoggerAPI
import SwiftCLI

// build the log format: "[date] [type] message"
let logFormat = "[%@] [%@] %@"
let logFormatValues: [HeliumLoggerFormatValues] = [.date, .logType, .message]
let logFormatArgs = logFormatValues.map { $0.rawValue }

// create the logger
let logger = HeliumLogger(.info)
logger.colored = true
logger.format = String(format: logFormat, arguments: logFormatArgs)

// set the logger
Log.logger = logger

// setup the command line interface
let cli = CLI(name: "class-generator", version: "1.0.3", description: "class-generator - Generate classes from JSON schemas")
cli.commands = [GenerateCommand()]

// run the command line interface
let _ = cli.go()
