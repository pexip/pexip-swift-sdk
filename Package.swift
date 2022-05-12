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
            checksum: "68d6ac8cf617990035fe66fffb175132f1f0eaca53946b6a8ad4fe5d1007ffeb"
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
            checksum: "be960d70fdd0d55d9a177cc87c4fdfd03883eca32e452b153197fd2e05b339dd"
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
            checksum: "986a8f43d44755d7e27a9fbf59ebc2ae41fdf4e038f3ac486f6b098b945a7c8a"
        ),
        // PexipMedia
        .binaryTarget(
            name: "PexipMedia",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.2.0/PexipMedia.xcframework.zip",
            checksum: "6dd21f2098d5399016984970c33286dd5f1cac7f9f79e5bee6214e607471e36b"
        ),
        // PexipUtils
        .binaryTarget(
            name: "PexipUtils",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.2.0/PexipUtils.xcframework.zip",
            checksum: "32bcd1cd83039f8433cdab0fabaad5345d847b3be9d966d9bc66e5635cad247b"
        ),
        // WebRTC
        .binaryTarget(
            name: "WebRTC",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.2.0/WebRTC.xcframework.zip",
            checksum: "1ddefa62bfe01fbb2fbebea94c7c7992a26e09d3f0ee6c18ee008f62f498ce6f"
        )
    ]
)
