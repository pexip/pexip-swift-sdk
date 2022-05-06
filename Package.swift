// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Pexip",
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
                .target(name: "PexipMedia")
            ],
            path: "Sources/PexipConference"
        ),
        .binaryTarget(
            name: "PexipConference",
            url: "https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64462957.zip",
            checksum: "b84379d99379818fc7827892d777cd81ad93fb1da47ee870512350300dbae249"
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
            url: "https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64462996.zip",
            checksum: "fb68522539aa7acbb59be580efe8a80736a925ace96e057ffa426ef3445fdbb4"
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
            url: "https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64463032.zip",
            checksum: "ad0f6638fbc595f6027b27a444b6c4c96551848d0c943db9241e6b2bc66d0e5d"
        ),
        // PexipMedia
        .binaryTarget(
            name: "PexipMedia",
            url: "https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64463025.zip",
            checksum: "bde85f3062f9d1211cd222a6812dfeafc4fbd3e60db81436132c97e04a288240"
        ),
        // PexipUtils
        .binaryTarget(
            name: "PexipUtils",
            url: "https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64463054.zip",
            checksum: "8e6645a6859847fae77fbf9dddbe201cfae8d24f6d27d1b97ca841bdeff125e7"
        ),
        // WebRTC
        .binaryTarget(
            name: "WebRTC",
            url: "https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64463162.zip",
            checksum: "ebfcf41e5171fa2c34cf06b6378f499fa41cf96435b4d32446d8cab73fff700a"
        )
    ]
)
