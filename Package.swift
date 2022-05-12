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
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/untagged-1c543b808d9d4f62485f/PexipConference.xcframework.zip",
            checksum: "33652933aa75c035fe137530a36a5fa4db0a50378546dcc396f613f3549886fb"
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
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/untagged-1c543b808d9d4f62485f/PexipInfinityClient.xcframework.zip",
            checksum: "1573c8e71bb888f0c781b96c393e7b5a6c28e3d96496f58b0318bfa376558e14"
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
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/untagged-1c543b808d9d4f62485f/PexipRTC.xcframework.zip",
            checksum: "2990833e960ea03e74614abbc6feccc8895be361dc575f8b205bcd7842f0482c"
        ),
        // PexipMedia
        .binaryTarget(
            name: "PexipMedia",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/untagged-1c543b808d9d4f62485f/PexipMedia.xcframework.zip",
            checksum: "b226abb3e5e6fbcb4ea5fc81f7d3055372a946e7cf994171915df76593c45a52"
        ),
        // PexipUtils
        .binaryTarget(
            name: "PexipUtils",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/untagged-1c543b808d9d4f62485f/PexipUtils.xcframework.zip",
            checksum: "9127507a58116de6b746ae7753193b9b4411f832fe939da0e593e85fe528f80e"
        ),
        // WebRTC
        .binaryTarget(
            name: "WebRTC",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/untagged-1c543b808d9d4f62485f/WebRTC.xcframework.zip",
            checksum: "1ddefa62bfe01fbb2fbebea94c7c7992a26e09d3f0ee6c18ee008f62f498ce6f"
        )
    ]
)
