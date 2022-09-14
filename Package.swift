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
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.5.0/PexipInfinityClient.xcframework.zip",
            checksum: "d1e0c3432def50f07133964d4cd79e3c3872a12fc7262ec526b4593221b3b56e"
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
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.5.0/PexipRTC.xcframework.zip",
            checksum: "0f356baf38fdf88daf08168d7891422f1f69d3060d550973e60015721dfff701"
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
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.5.0/PexipMedia.xcframework.zip",
            checksum: "f60cc73e22d3eff93f4816477b8ef08b99f6d9ffe47c115e11fa150c7478c014"
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
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.5.0/PexipVideoFilters.xcframework.zip",
            checksum: "2a1b53879ef0fe25d4ccba764dddc28b2c4411d9a53cffed6c403c8eb341132e"
        ),

        // PexipScreenCapture
        .binaryTarget(
            name: "PexipScreenCapture",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.5.0/PexipScreenCapture.xcframework.zip",
            checksum: "e135d5363692c2247f71158ffdcea17087f19f77b0b749cc4c3a838c12586ec7"
        ),

        // PexipCore
        .binaryTarget(
            name: "PexipCore",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.5.0/PexipCore.xcframework.zip",
            checksum: "6bc4d08f1be35544fbbe26956cf0ea73eb8b1b679f9308b98a4fc18f2a67828f"
        ),

        // WebRTC
        .binaryTarget(
            name: "WebRTC",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.5.0/WebRTC.xcframework.zip",
            checksum: "921c2bc805f04fdb22b2cc97f67e4bf33c538845d0097e620e635194dd68d9c3"
        )
    ]
)
