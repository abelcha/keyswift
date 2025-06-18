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
            name: "keyshift",
            targets: ["keyshift"]),
        .executable(
            name: "keyshift-logs",
            targets: ["keyshift-logs"])
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
            name: "keyshift",
            dependencies: ["KeyShift"],
            path: "Sources/KeyShiftApp",
            resources: [
                .copy("Resources/KeyShift.entitlements")
            ]),
        .executableTarget(
            name: "keyshift-logs",
            dependencies: ["KeyShift"],
            path: "Sources/KeyShiftLogs")
    ]
)
