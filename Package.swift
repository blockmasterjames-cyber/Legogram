// swift-tools-version: 5.9
// This file tells Xcode which external packages (like Firebase) to download.
// Add this package to your Xcode project via File > Add Package Dependencies
// and point it at: https://github.com/firebase/firebase-ios-sdk

import PackageDescription

let package = Package(
    name: "LegoGram",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [
        // Firebase iOS SDK — provides Auth, Firestore, Storage, Analytics
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk",
            from: "11.0.0"
        )
    ],
    targets: [
        .target(
            name: "LegoGram",
            dependencies: [
                .product(name: "FirebaseAuth",      package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage",   package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk")
            ],
            path: "LegoGram"
        )
    ]
)
