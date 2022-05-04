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
            path: "PexipConference"
        ),
        .binaryTarget(
            name: "PexipConference",
            url: "https://api.github.com/repos/pexip/pexip-ios-sdk-builds/releases/assets/64440621.zip",
            checksum: "3df7478f2f3d8353f6ad9659c52fe3eae572d2681c2e802023b6bf11422ad600"
        ),
        // PexipInfinityClient
        .target(name: "PexipInfinityClientTargets",
            dependencies: [
                .target(name: "PexipInfinityClient"),
                .target(name: "PexipUtils")
            ],
            path: "PexipInfinityClient"
        ),
        .binaryTarget(
            name: "PexipInfinityClient",
            url: "https://api.github.com/repos/pexip/pexip-ios-sdk-builds/releases/assets/64440624.zip",
            checksum: "0932c5c8fb88bd851abc22f5d94287307aa7f04d34e7042814af7e0d154b91d0"
        ),
        // PexipRTC
        .target(name: "PexipRTCTargets",
            dependencies: [
                .target(name: "PexipRTC"),
                .target(name: "PexipUtils"),
                .target(name: "PexipMedia"),
                .target(name: "WebRTC")
            ],
            path: "PexipRTC"
        ),
        .binaryTarget(
            name: "PexipRTC",
            url: "https://api.github.com/repos/pexip/pexip-ios-sdk-builds/releases/assets/64440632.zip",
            checksum: "1f8681918fac30b41ad91206d02b03570a460548663c738007adc08ff224fc6b"
        ),
        // PexipMedia
        .binaryTarget(
            name: "PexipMedia",
            url: "https://api.github.com/repos/pexip/pexip-ios-sdk-builds/releases/assets/64440625.zip",
            checksum: "1a74aa798d7058d1fdd0a42a4a1449fb9616072b0916988fad11f6c1011a28ec"
        ),
        // PexipUtils
        .binaryTarget(
            name: "PexipUtils",
            url: "https://api.github.com/repos/pexip/pexip-ios-sdk-builds/releases/assets/64440635.zip",
            checksum: "f2fa7924f6417c7fc226a7348ca9631c32b30163b3914e5f297d7e7efc02c37f"
        ),
        // WebRTC
        .binaryTarget(
            name: "WebRTC",
            url: "https://api.github.com/repos/pexip/pexip-ios-sdk-builds/releases/assets/64440647.zip",
            checksum: "ebfcf41e5171fa2c34cf06b6378f499fa41cf96435b4d32446d8cab73fff700a"
        )
    ]
)
