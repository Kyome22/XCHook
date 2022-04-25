// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XCMonitor",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "XCMonitor",
            targets: ["XCMonitor"]
        )
    ],
    targets: [
        .target(
            name: "XCMonitor",
            dependencies: [],
            resources: [
                .copy("plists"),
                .copy("run_scripts"),
                .copy("Message.txt")
            ]
        ),
        .testTarget(
            name: "XCMonitorTests",
            dependencies: ["XCMonitor"]
        )
    ]
)
