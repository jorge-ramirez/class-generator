// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "class-generator",
    dependencies: [
        .package(url: "https://github.com/kylef/PathKit.git", from: "0.8.0"),
        .package(url: "https://github.com/kylef/Stencil.git", from: "0.10.1"),
        .package(url: "https://github.com/jakeheis/SwiftCLI.git", from: "4.0.3")
    ],
    targets: [
        .target(
            name: "class-generator",
            dependencies: ["PathKit", "Stencil", "SwiftCLI"])
    ]
)
