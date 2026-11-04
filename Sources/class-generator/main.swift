import HeliumLogger
import LoggerAPI

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

// configure and run the command line interface
ClassGeneratorCommand.main()
