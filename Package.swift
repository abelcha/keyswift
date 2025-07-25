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
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
        .package(url: "https://github.com/emorydunn/LaunchAgent.git", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "KeyShift",
            dependencies: ["Yams", "LaunchAgent"],
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath(".")
            ]),
        .executableTarget(
            name: "keyshift",
            dependencies: ["KeyShift"],
            path: "Sources/KeyShiftApp",
            resources: [
                .copy("Resources/KeyShift.entitlements"),
                .copy("Resources/browser-icon.svg")
            ]),
        .executableTarget(
            name: "keyshift-logs",
            dependencies: ["KeyShift"],
            path: "Sources/KeyShiftLogs")
    ]
)
