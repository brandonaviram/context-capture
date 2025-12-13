// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ContextCaptureBrain",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/stephencelis/SQLite.swift", from: "0.15.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "ContextCaptureBrain",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SQLite", package: "SQLite.swift"),
                .product(name: "Hummingbird", package: "hummingbird"),
            ]
        ),
    ]
)
