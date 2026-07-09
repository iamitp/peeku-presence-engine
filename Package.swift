// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "PeekuPresenceEngine",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "PeekuPresenceEngine",
            targets: ["PeekuPresenceEngine"]
        )
    ],
    targets: [
        .target(name: "PeekuPresenceEngine"),
        .testTarget(
            name: "PeekuPresenceEngineTests",
            dependencies: ["PeekuPresenceEngine"]
        )
    ]
)
