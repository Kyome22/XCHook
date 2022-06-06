// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XCHook",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "XCHook",
            targets: ["XCHook"]
        )
    ],
    targets: [
        .target(
            name: "XCHook",
            dependencies: [],
            resources: [
                .copy("plists"),
                .copy("run_scripts"),
                .copy("swift_script"),
                .copy("c_timestamp")
            ]
        ),
        .testTarget(
            name: "XCHookTests",
            dependencies: ["XCHook"]
        )
    ]
)
