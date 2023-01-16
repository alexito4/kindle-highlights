// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "kindle-highlights",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", exact: "1.2.0"),
        .package(url: "https://github.com/pointfreeco/swift-parsing.git", exact: "0.11.0"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump.git", exact: "0.6.1"),
        .package(url: "https://github.com/alexito4/Baggins.git", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "kindle-highlights",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Parsing", package: "swift-parsing"),
                "Baggins",
            ]
        ),
        .testTarget(
            name: "kindle-highlightsTests",
            dependencies: [
                "kindle-highlights",
                .product(name: "CustomDump", package: "swift-custom-dump"),
            ],
            resources: [
                .copy("TestData"),
            ]
        ),
    ]
)
