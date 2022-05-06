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
            url: "https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64686462.zip",
            checksum: "f06cc991c51f8e4b7e6644de5091dfc4fbc07a2154c17644ba2fb07ac032e472"
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
            url: "https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64686441.zip",
            checksum: "72b393cfcac8258088c1ef1d43feb43116fa2c204f7e0c616df30d487f2a689a"
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
            url: "https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64686452.zip",
            checksum: "0ff3a8e27142dce5c715754d539f81d9dfe724ac4e3de2036251ada25d68df0f"
        ),
        // PexipMedia
        .binaryTarget(
            name: "PexipMedia",
            url: "https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64686434.zip",
            checksum: "4f78c42b99fb1de9127e52b5a33312151a7f5552a2c9d649b8365ed38e98642f"
        ),
        // PexipUtils
        .binaryTarget(
            name: "PexipUtils",
            url: "https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64686429.zip",
            checksum: "e4b6e8fead3f1fac86bae44e5317f27f88ed27b315aa45213d802ea891fe4160"
        ),
        // WebRTC
        .binaryTarget(
            name: "WebRTC",
            url: "https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64686147.zip",
            checksum: "1ddefa62bfe01fbb2fbebea94c7c7992a26e09d3f0ee6c18ee008f62f498ce6f"
        )
    ]
)
