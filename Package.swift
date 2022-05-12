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
            checksum: "7da03bccaccf424070c73757b4d243b0872f812a989be4380c1e155ef70e214e"
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
            checksum: "281063d820b8f234945947907097d9fc5f24ca59a846f46849a9a2132350ee91"
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
            checksum: "681faec09ba1f17385a30dc1b5518d7aee0e2c0486e98f1ea472c2dbc17ed515"
        ),
        // PexipMedia
        .binaryTarget(
            name: "PexipMedia",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.2.0/PexipMedia.xcframework.zip",
            checksum: "0b7e54fce29c14c33c8392f7580e1b35152ee920d652591c8ef5e51493193505"
        ),
        // PexipUtils
        .binaryTarget(
            name: "PexipUtils",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.2.0/PexipUtils.xcframework.zip",
            checksum: "ba763cc4aaca620d3965bc4e2f18e8b6b0c7f900a6ddb0fdfa5dc95e25fa67f9"
        ),
        // WebRTC
        .binaryTarget(
            name: "WebRTC",
            url: "https://github.com/pexip/pexip-swift-sdk/releases/download/0.2.0/WebRTC.xcframework.zip",
            checksum: "1ddefa62bfe01fbb2fbebea94c7c7992a26e09d3f0ee6c18ee008f62f498ce6f"
        )
    ]
)
