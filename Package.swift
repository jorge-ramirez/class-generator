// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "class-generator",
    dependencies: [
        .package(url: "https://github.com/kylef/PathKit.git", .upToNextMajor(from: "0.8.0")),
        .package(url: "https://github.com/kylef/Stencil.git", .upToNextMajor(from: "0.10.1")),
        .package(url: "https://github.com/jakeheis/SwiftCLI.git", .upToNextMajor(from: "4.0.3")),
        .package(url: "https://github.com/Hearst-DD/ObjectMapper.git", .upToNextMajor(from: "3.1.0")),
        .package(url: "https://github.com/IBM-Swift/HeliumLogger.git", .upToNextMajor(from: "1.7.1"))
    ],
    targets: [
        .target(
            name: "class-generator",
            dependencies: ["PathKit", "Stencil", "SwiftCLI", "ObjectMapper", "HeliumLogger"])
    ]
)
