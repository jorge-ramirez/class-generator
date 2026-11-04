import Logging

// configure the logger
LoggingSystem.bootstrap { label in
    var handler = StreamLogHandler.standardOutput(label: label)
    handler.logLevel = .info
    return handler
}

// configure and run the command line interface
ClassGeneratorCommand.main()
