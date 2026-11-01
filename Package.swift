// swift-tools-version:6.0
// AssetsAgent: everything an iOS + macOS asset catalog needs to brand an app, drawn on the Mac, as a Granite agent
// package. An app that links it finds the `assets` agent through Granite's roster, with nothing listed by hand.

import PackageDescription

let package = Package(
    name: "AssetsAgent",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "AssetsAgent", targets: ["AssetsAgent"]),
    ],
    dependencies: [
        .package(url: "https://github.com/riteshpakala/Granite.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "AssetsAgent",
            dependencies: [.product(name: "GraniteAgents", package: "Granite")],
            swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(
            name: "AssetsAgentTests",
            dependencies: ["AssetsAgent", .product(name: "GraniteAgents", package: "Granite")],
            swiftSettings: [.swiftLanguageMode(.v6)]),
    ]
)
