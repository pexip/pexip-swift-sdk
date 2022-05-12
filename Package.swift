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
            name: "PexipConference",
            targets: ["PexipConferenceTargets"]
        ),
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
            targets: ["PexipMedia"]
        ),
        .library(
            name: "PexipUtils",
            targets: ["PexipUtils"]
        ),
        .library(
            name: "WebRTC",
            targets: ["WebRTC"]
        )
    ],
    targets: [
        // PexipConference
        .target(name: "PexipConferenceTargets",
            dependencies: [
                .target(name: "PexipConference"),
                .target(name: "PexipInfinityClient"),
                .target(name: "PexipMedia"),
                .target(name: "PexipUtils")
            ],
            path: "Sources/PexipConference"
        ),
        .binaryTarget(
            name: "PexipConference",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.2.0/PexipConference.xcframework.zip",
            checksum: "0dc20fdc87bbe8416298778c4ca05a023f12d1872ce19c04a7896e22b464c30c"
        ),
        // PexipInfinityClient
        .target(name: "PexipInfinityClientTargets",
            dependencies: [
                .target(name: "PexipInfinityClient"),
                .target(name: "PexipUtils")
            ],
            path: "Sources/PexipInfinityClient"
        ),
        .binaryTarget(
            name: "PexipInfinityClient",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.2.0/PexipInfinityClient.xcframework.zip",
            checksum: "fc57256dabf58a02b103271c37121b2a841146449d99addebaa82ca071898db3"
        ),
        // PexipRTC
        .target(name: "PexipRTCTargets",
            dependencies: [
                .target(name: "PexipRTC"),
                .target(name: "PexipUtils"),
                .target(name: "PexipMedia"),
                .target(name: "WebRTC")
            ],
            path: "Sources/PexipRTC"
        ),
        .binaryTarget(
            name: "PexipRTC",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.2.0/PexipRTC.xcframework.zip",
            checksum: "44cb87cdfec5ff38e05791133440b8e5870a2653afc7422df272be05e7dcdcc8"
        ),
        // PexipMedia
        .binaryTarget(
            name: "PexipMedia",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.2.0/PexipMedia.xcframework.zip",
            checksum: "d1ca6e395896a8b967c4b96e5c8d8c7e52fb9b13e5b79106f1b11cc4a9333490"
        ),
        // PexipUtils
        .binaryTarget(
            name: "PexipUtils",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.2.0/PexipUtils.xcframework.zip",
            checksum: "3618e2c0de032cf76f8ac3a3538e1cac501083a5c1871020c34bf71f5f6782b4"
        ),
        // WebRTC
        .binaryTarget(
            name: "WebRTC",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.2.0/WebRTC.xcframework.zip",
            checksum: "1ddefa62bfe01fbb2fbebea94c7c7992a26e09d3f0ee6c18ee008f62f498ce6f"
        )
    ]
)
