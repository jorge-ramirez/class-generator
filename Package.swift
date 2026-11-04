// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "class-generator",
    dependencies: [
        .package(url: "https://github.com/kylef/PathKit.git", .upToNextMajor(from: "0.8.0")),
        .package(url: "https://github.com/kylef/Stencil.git", .upToNextMajor(from: "0.10.1")),
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMinor(from: "1.2.0")),
        .package(url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        .executableTarget(
            name: "class-generator",
            dependencies: [
                "PathKit",
                "Stencil",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
            ])
    ]
)
