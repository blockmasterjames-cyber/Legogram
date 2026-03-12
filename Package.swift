// swift-tools-version: 5.9
// This file tells Xcode which external packages to download.
// Firebase has been temporarily removed — it will be added back in Sprint 3.

import PackageDescription

let package = Package(
    name: "BrickFeed",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [],
    targets: [
        .target(
            name: "BrickFeed",
            dependencies: [],
            path: "LegoGram"
        )
    ]
)
