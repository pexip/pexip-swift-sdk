// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
            targets: ["PexipConference"]
        ),
        .library(
            name: "PexipInfinityClient",
            targets: ["PexipInfinityClient"]
        ),
        .library(
            name: "PexipMedia",
            targets: ["PexipMedia"]
        ),
        .library(
            name: "PexipRTC",
            targets: ["PexipRTC"]
        ),
        .library(
            name: "PexipUtils",
            targets: ["PexipUtils"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/pexip/webrtc-ios-builds",
            .exactItem("96.0.4664")
        )
    ],
    targets: [
        // PexipConference
        .target(
            name: "PexipConference",
            dependencies: ["PexipInfinityClient", "PexipMedia"]
        ),
        .testTarget(
            name: "PexipConferenceTests",
            dependencies: ["PexipConference"]
        ),
        // PexipInfinityClient
        .target(
            name: "PexipInfinityClient",
            dependencies: ["PexipUtils"]
        ),
        .testTarget(
            name: "PexipInfinityClientTests",
            dependencies: ["PexipInfinityClient"]
        ),
        // PexipMedia
        .target(
            name: "PexipMedia",
            dependencies: ["PexipUtils"]
        ),
        .testTarget(
            name: "PexipMediaTests",
            dependencies: ["PexipMedia"],
            resources: [
                .copy("Resources/testVideo.mp4")
            ]
        ),
        // PexipRTC
        .target(
            name: "PexipRTC",
            dependencies: [
                "PexipMedia",
                .product(name: "WebRTC", package: "webrtc-ios-builds")
            ]
        ),
        .testTarget(
            name: "PexipRTCTests",
            dependencies: ["PexipRTC"]
        ),
        // PexipUtils
        .target(
            name: "PexipUtils"
        ),
        .testTarget(
            name: "PexipUtilsTests",
            dependencies: ["PexipUtils"]
        )
    ]
)
