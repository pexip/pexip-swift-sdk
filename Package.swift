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
            url: "https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64679300.zip",
            checksum: "11b66f28b453ab210dd9df919848dea404c74660d85ed37fd7a0a0aa2e0e2032"
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
            url: "https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64679307.zip",
            checksum: "2350d6ed0100c95fd722c21940f27e358b24c9d8d8665e54c90f0f89c2fa9acf"
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
            url: "https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64679342.zip",
            checksum: "24d4b39ac5719fb68125cb572f0c00f7b5d88ad76c92f3a95f1151d686d4e64a"
        ),
        // PexipMedia
        .binaryTarget(
            name: "PexipMedia",
            url: "https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64679315.zip",
            checksum: "cf47ef560094c5dd963b9aea93b7ce0750ca9b82b771ed59e638a5769d08dfb2"
        ),
        // PexipUtils
        .binaryTarget(
            name: "PexipUtils",
            url: "https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64679388.zip",
            checksum: "115626200bd781d69732cbb8b6cd56061d73a6e979d89428659a899fda59676a"
        ),
        // WebRTC
        .binaryTarget(
            name: "WebRTC",
            url: "https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64679615.zip",
            checksum: "1ddefa62bfe01fbb2fbebea94c7c7992a26e09d3f0ee6c18ee008f62f498ce6f"
        )
    ]
)
