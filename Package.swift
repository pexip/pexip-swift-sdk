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
            url: "https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64683696.zip",
            checksum: "042df7a6d3ac701ac4512390a758d6b7f69507ea8458a33dfcff14849663db34"
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
            url: "https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64683704.zip",
            checksum: "3df12b0d95eb885eec7500d57fb16d484156ae3d07da1eaffbc6aaadab1664dc"
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
            url: "https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64683719.zip",
            checksum: "77df20a0a5e75a40e016a6ea26a6438cd632873e3d960bbfdb82f7ea473d5739"
        ),
        // PexipMedia
        .binaryTarget(
            name: "PexipMedia",
            url: "https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64683713.zip",
            checksum: "0dfc4d8029ae4f205ec5bd34da12406a0b98c5d39bb557125be053b6604c66e6"
        ),
        // PexipUtils
        .binaryTarget(
            name: "PexipUtils",
            url: "https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64683724.zip",
            checksum: "d52eaa306d8ca799ea9dfe57cb039c59a7414b2235d6930c64217f77c14342de"
        ),
        // WebRTC
        .binaryTarget(
            name: "WebRTC",
            url: "https://api.github.com/repos/pexip/pexip-swift-sdk/releases/assets/64683769.zip",
            checksum: "1ddefa62bfe01fbb2fbebea94c7c7992a26e09d3f0ee6c18ee008f62f498ce6f"
        )
    ]
)
