// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FortachonCore",
    platforms: [.macOS(.v15), .iOS(.v18)],
    products: [
        .library(
            name: "FortachonCore",
            targets: ["FortachonCore"]),
    ],
    targets: [
        .target(
            name: "FortachonCore"),
        .testTarget(
            name: "FortachonCoreTests",
            dependencies: ["FortachonCore"]),
    ]
)