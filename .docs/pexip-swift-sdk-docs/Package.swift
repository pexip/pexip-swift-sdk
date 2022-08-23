// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "pexip-swift-sdk-docs",
    products: [
        .library(
            name: "PexipSwiftSDK",
            targets: ["PexipSwiftSDK"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-docc-plugin",
            branch: "1.0.0"
        )
    ],
    targets: [
        .target(
            name: "PexipSwiftSDK",
            dependencies: []
        ),
        .testTarget(
            name: "PexipSwiftSDKTests",
            dependencies: ["PexipSwiftSDK"]
        )
    ]
)
