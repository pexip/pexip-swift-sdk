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
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.4.0/PexipInfinityClient.xcframework.zip",
            checksum: "c7c0f61949b80b597d44abe282d7e4e942139c83d4d2f1d08f9738f033107efa"
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
            path: "Sources/PexipRTC",
            cSettings: [
                .unsafeFlags(["-w"])
            ]
        ),
        .binaryTarget(
            name: "PexipRTC",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.4.0/PexipRTC.xcframework.zip",
            checksum: "c117a89ace91ffb469de752f99043c1f3c1f356053fba862cee8e42440f2dbb7"
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
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.4.0/PexipMedia.xcframework.zip",
            checksum: "23bca19db5ef0cd67df376966600b76f0fe5cd9ab6e0d70cb44bc102f2e0eb09"
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
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.4.0/PexipVideoFilters.xcframework.zip",
            checksum: "23bca19db5ef0cd67df376966600b76f0fe5cd9ab6e0d70cb44bc102f2e0eb09"
        ),

        // PexipScreenCapture
        .binaryTarget(
            name: "PexipScreenCapture",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.4.0/PexipScreenCapture.xcframework.zip",
            checksum: "e672b276f94679d208e8b69e285991f4b6bed3c9a1ca7617ea2e3524fd6a7988"
        ),

        // PexipCore
        .binaryTarget(
            name: "PexipCore",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.4.0/PexipUtils.xcframework.zip",
            checksum: "e672b276f94679d208e8b69e285991f4b6bed3c9a1ca7617ea2e3524fd6a7988"
        ),

        // WebRTC
        .binaryTarget(
            name: "WebRTC",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.4.0/WebRTC.xcframework.zip",
            checksum: "1ddefa62bfe01fbb2fbebea94c7c7992a26e09d3f0ee6c18ee008f62f498ce6f"
        )
    ]
)
