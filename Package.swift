// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "PexipSDK",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "PexipInfinityClient",
            targets: ["PexipInfinityClientTargets"]
        ),
        .library(
            name: "PexipRTC",
            targets: ["PexipRTCTargets"]
        ),
        .library(
            name: "PexipMedia",
            targets: ["PexipMediaTargets"]
        ),
        .library(
            name: "PexipVideoFilters",
            targets: ["PexipVideoFiltersTargets"]
        ),
        .library(
            name: "PexipScreenCapture",
            targets: ["PexipScreenCapture"]
        ),
        .library(
            name: "PexipCore",
            targets: ["PexipCore"]
        ),
        .library(
            name: "WebRTC",
            targets: ["WebRTC"]
        )
    ],
    targets: [
        // PexipInfinityClient
        .target(name: "PexipInfinityClientTargets",
            dependencies: [
                .target(name: "PexipInfinityClient"),
                .target(name: "PexipCore")
            ],
            path: "Sources/PexipInfinityClient"
        ),
        .binaryTarget(
            name: "PexipInfinityClient",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.6.0/PexipInfinityClient.xcframework.zip",
            checksum: "5df2a82fde5daded078c37b03fa474c183cc9751672d1fb2dbfdcc0e8b5d60bf"
        ),

        // PexipRTC
        .target(name: "PexipRTCTargets",
            dependencies: [
                .target(name: "PexipRTC"),
                .target(name: "PexipMedia"),
                .target(name: "PexipCore"),
                .target(name: "PexipScreenCapture"),
                .target(name: "WebRTC")
            ],
            path: "Sources/PexipRTC"
        ),
        .binaryTarget(
            name: "PexipRTC",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.6.0/PexipRTC.xcframework.zip",
            checksum: "6d6eb6eea3ffe2e43da5ceaeb3ba795f55b6dd2e2644423b3baf145779a31aad"
        ),

        // PexipMedia
        .target(name: "PexipMediaTargets",
            dependencies: [
                .target(name: "PexipMedia"),
                .target(name: "PexipCore"),
                .target(name: "PexipScreenCapture")
            ],
            path: "Sources/PexipMedia"
        ),
        .binaryTarget(
            name: "PexipMedia",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.6.0/PexipMedia.xcframework.zip",
            checksum: "d5686636b656b1f832b2e1f1a69960fbdf550055f0c1df6648e8a75c10794577"
        ),

        // PexipVideoFilters
        .target(name: "PexipVideoFiltersTargets",
            dependencies: [
                .target(name: "PexipVideoFilters"),
                .target(name: "PexipCore")
            ],
            path: "Sources/PexipVideoFilters"
        ),
        .binaryTarget(
            name: "PexipVideoFilters",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.6.0/PexipVideoFilters.xcframework.zip",
            checksum: "a30f9f42fe315c0377eeac6724f883b4174608c2c91f46bcbc34a3f8c82369cf"
        ),

        // PexipScreenCapture
        .binaryTarget(
            name: "PexipScreenCapture",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.6.0/PexipScreenCapture.xcframework.zip",
            checksum: "c5574e0dde04fb75c090276bee116751715a6977414a7542a37bcecd2640790a"
        ),

        // PexipCore
        .binaryTarget(
            name: "PexipCore",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.6.0/PexipCore.xcframework.zip",
            checksum: "2ca52190d8488e2ec0b14715ac18f8b503f80b633689cc0040da44445b0fe989"
        ),

        // WebRTC
        .binaryTarget(
            name: "WebRTC",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.6.0/WebRTC.xcframework.zip",
            checksum: "9178e1a2623c7215c9313fa4e6710a9a209badc8d99cee85f3e732b68c1d9675"
        )
    ]
)
