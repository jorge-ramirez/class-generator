import ArgumentParser

internal struct ClassGeneratorCommand: ParsableCommand {

    // MARK: - Command Configuration

    internal static let configuration: CommandConfiguration = CommandConfiguration(
        commandName: "class-generator",
        abstract: "class-generator - Generate classes from JSON schemas",
        version: Version.current,
        subcommands: [GenerateCommand.self])

}
