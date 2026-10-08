// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CalisthenicsSymbols",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "CalisthenicsSymbols", targets: ["CalisthenicsSymbols"]),
    ],
    targets: [
        .target(
            name: "CalisthenicsSymbols",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "CalisthenicsSymbolsTests",
            dependencies: ["CalisthenicsSymbols"]
        ),
    ]
)
