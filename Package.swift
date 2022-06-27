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
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.3.0/PexipConference.xcframework.zip",
            checksum: "b48d3b6fad4702633909dc429a9ec445dbc6c6b2ed93a725a6a1a13dc9cbecb3"
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
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.3.0/PexipInfinityClient.xcframework.zip",
            checksum: "9bf385f5e5e6c8200c076d13e0e27978d553b75d343baab3e4e456ab999427c2"
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
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.3.0/PexipRTC.xcframework.zip",
            checksum: "dc1b613ee53f81c470e7b3484eaa00ab1f413b61c219be0f21c4e7c948c65d0b"
        ),
        // PexipMedia
        .binaryTarget(
            name: "PexipMedia",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.3.0/PexipMedia.xcframework.zip",
            checksum: "33f3b0532549771db8bd178ff47978cff815ba39297804707858707ec26f2575"
        ),
        // PexipUtils
        .binaryTarget(
            name: "PexipUtils",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.3.0/PexipUtils.xcframework.zip",
            checksum: "370408dc504855ed7ca49d15a321fa186f3bb36dc64072f52bc9447e8054038a"
        ),
        // WebRTC
        .binaryTarget(
            name: "WebRTC",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.3.0/WebRTC.xcframework.zip",
            checksum: "1ddefa62bfe01fbb2fbebea94c7c7992a26e09d3f0ee6c18ee008f62f498ce6f"
        )
    ]
)
