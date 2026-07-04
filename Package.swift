// swift-tools-version: 6.2

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
]

let package = Package(
    name: "XCHook",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "XCHook",
            targets: ["XCHook"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "1.1.0")
    ],
    targets: [
        .target(
            name: "XCHook",
            dependencies: [
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ],
            resources: [
                .copy("run_scripts")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "XCHookTests",
            dependencies: ["XCHook"],
            swiftSettings: swiftSettings
        )
    ]
)
