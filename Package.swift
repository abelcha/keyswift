// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "KeyShift",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "KeyShiftLib",
            targets: ["KeyShift"]),
        .executable(
            name: "KeyShiftApp",
            targets: ["KeyShiftApp"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "KeyShift",
            dependencies: [],
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath(".")
            ]),
        .executableTarget(
            name: "KeyShiftApp",
            dependencies: ["KeyShift"],
            path: "Sources/KeyShiftApp",
            resources: [
                .copy("Resources/KeyShift.entitlements")
            ])
    ]
)
