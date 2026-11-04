// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "class-generator",
    dependencies: [
        .package(url: "https://github.com/kylef/PathKit.git", .upToNextMajor(from: "0.8.0")),
        .package(url: "https://github.com/kylef/Stencil.git", .upToNextMajor(from: "0.10.1")),
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMinor(from: "1.2.0")),
        .package(url: "https://github.com/Hearst-DD/ObjectMapper.git", .upToNextMajor(from: "3.1.0")),
        .package(url: "https://github.com/IBM-Swift/HeliumLogger.git", .upToNextMajor(from: "1.7.1"))
    ],
    targets: [
        .executableTarget(
            name: "class-generator",
            dependencies: [
                "PathKit",
                "Stencil",
                "ObjectMapper",
                "HeliumLogger",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ])
    ]
)
