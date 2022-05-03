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
            url: "#PexipConference_url",
            checksum: "#PexipConference_checksum"
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
            url: "#PexipInfinityClient_url",
            checksum: "#PexipInfinityClient_checksum"
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
            url: "#PexipRTC_url",
            checksum: "#PexipRTC_checksum"
        ),
        // PexipMedia
        .binaryTarget(
            name: "PexipMedia",
            url: "#PexipMedia_url",
            checksum: "#PexipMedia_checksum"
        ),
        // PexipUtils
        .binaryTarget(
            name: "PexipUtils",
            url: "#PexipUtils_url",
            checksum: "#PexipUtils_checksum"
        ),
        // WebRTC
        .binaryTarget(
            name: "WebRTC",
            url: "#WebRTC_url",
            checksum: "#WebRTC_checksum"
        )
    ]
)
