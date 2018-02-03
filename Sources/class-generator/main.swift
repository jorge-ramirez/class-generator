import HeliumLogger
import LoggerAPI
import SwiftCLI

// setup logging
let logger = HeliumLogger(.info)
logger.colored = true
logger.format = "[(%date)] [(%type)] (%msg)"
Log.logger = logger

// setup the command line interface
let cli = CLI(name: "class-generator", version: "1.0.1", description: "class-generator - Generate classes from JSON schemas")
cli.commands = [GenerateCommand()]

// run the command line interface
let _ = cli.go()
