// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MpesaSDK",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "MpesaSDK",
            targets: ["MpesaSDK"]
        )
    ],
    targets: [
        .target(
            name: "MpesaSDK",
            dependencies: [],
            path: "Sources/MpesaSDK"
        ),
        .testTarget(
            name: "MpesaSDKTests",
            dependencies: ["MpesaSDK"],
            path: "Tests/MpesaSDKTests"
        )
    ]
)
