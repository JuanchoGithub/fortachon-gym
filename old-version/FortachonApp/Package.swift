// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FortachonApp",
    platforms: [.iOS(.v18), .macOS(.v15)],
    dependencies: [
        .package(path: "../FortachonCore"),
    ],
    targets: [
        .executableTarget(
            name: "FortachonApp",
            dependencies: ["FortachonCore"]),
    ]
)
