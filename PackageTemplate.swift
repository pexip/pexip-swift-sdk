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
            url: "PexipInfinityClient_url",
            checksum: "PexipInfinityClient_checksum"
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
            url: "PexipRTC_url",
            checksum: "PexipRTC_checksum"
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
            url: "PexipMedia_url",
            checksum: "PexipMedia_checksum"
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
            url: "PexipVideoFilters_url",
            checksum: "PexipVideoFilters_checksum"
        ),

        // PexipScreenCapture
        .binaryTarget(
            name: "PexipScreenCapture",
            url: "PexipScreenCapture_url",
            checksum: "PexipScreenCapture_checksum"
        ),

        // PexipCore
        .binaryTarget(
            name: "PexipCore",
            url: "PexipCore_url",
            checksum: "PexipCore_checksum"
        ),

        // WebRTC
        .binaryTarget(
            name: "WebRTC",
            url: "WebRTC_url",
            checksum: "WebRTC_checksum"
        )
    ]
)
