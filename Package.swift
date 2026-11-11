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
        ),
        .executable(name: "pulse-demo", targets: ["PulseDemo"])
    ],
    targets: [
        .target(name: "PeekuPresenceEngine"),
        .executableTarget(
            name: "PulseDemo",
            dependencies: ["PeekuPresenceEngine"],
            path: "Examples/PulseDemo"
        ),
        .testTarget(
            name: "PeekuPresenceEngineTests",
            dependencies: ["PeekuPresenceEngine"]
        )
    ]
)
