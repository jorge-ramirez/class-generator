import SwiftCLI

let cli = CLI(name: "class-generator", version: "0.0.1", description: "class-generator - Generate classes from JSON schemas")
cli.commands = [GenerateCommand()]
let _ = cli.go()
