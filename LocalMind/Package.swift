// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LocalMind",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "LocalMind",
            targets: ["LocalMind"]),
    ],
    targets: [
        .target(
            name: "LocalMind",
            dependencies: [],
            path: "Sources",
            resources: [.process("Resources")],
            swiftSettings: [.define("SWIFTPM")]),
        .testTarget(
            name: "LocalMindTests",
            dependencies: ["LocalMind"],
            path: "Tests"),
    ]
)
