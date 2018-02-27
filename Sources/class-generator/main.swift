import HeliumLogger
import LoggerAPI
import SwiftCLI

// build the log format: "[date] [type] message"
private let logFormat = "[%@] [%@] %@"
private let logFormatValues: [HeliumLoggerFormatValues] = [.date, .logType, .message]
private let logFormatArgs = logFormatValues.map { $0.rawValue }

// create the logger
private let logger = HeliumLogger(.info)

// configure the logger
logger.colored = true
logger.format = String(format: logFormat, arguments: logFormatArgs)

// set the logger instance
Log.logger = logger

// setup the command line interface
private let cli = CLI(name: "class-generator",
                      version: "1.0.8",
                      description: "class-generator - Generate classes from JSON schemas")

// configure and run the command line interface
cli.commands = [GenerateCommand()]
_ = cli.go()
