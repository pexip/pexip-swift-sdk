// swift-tools-version:5.6
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
        ),
        .library(
            name: "PexipVideoFilters",
            targets: ["PexipVideoFilters"]
        ),
        .library(
            name: "PexipScreenCapture",
            targets: ["PexipScreenCapture"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/pexip/webrtc-ios-builds",
            exact: .init(96, 0, 4664)
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
            from: "1.9.0"
        )
    ],
    targets: [
        // MARK: - PexipConference

        .target(
            name: "PexipConference",
            dependencies: ["PexipInfinityClient", "PexipMedia"]
        ),
        .testTarget(
            name: "PexipConferenceTests",
            dependencies: ["PexipConference"]
        ),

        // MARK: - PexipInfinityClient

        .target(
            name: "PexipInfinityClient",
            dependencies: ["PexipUtils"]
        ),
        .testTarget(
            name: "PexipInfinityClientTests",
            dependencies: ["PexipInfinityClient"]
        ),

        // MARK: - PexipMedia

        .target(
            name: "PexipMedia",
            dependencies: ["PexipScreenCapture"]
        ),
        .testTarget(
            name: "PexipMediaTests",
            dependencies: ["PexipMedia", "TestHelpers"]
        ),

        // MARK: - PexipRTC

        .target(
            name: "PexipRTC",
            dependencies: [
                "PexipMedia",
                "PexipUtils",
                .product(name: "WebRTC", package: "webrtc-ios-builds")
            ]
        ),
        .testTarget(
            name: "PexipRTCTests",
            dependencies: ["PexipRTC"]
        ),

        // MARK: -  PexipUtils

        .target(
            name: "PexipUtils"
        ),
        .testTarget(
            name: "PexipUtilsTests",
            dependencies: ["PexipUtils"]
        ),

        // MARK: - PexipVideoFilters

        .target(
            name: "PexipVideoFilters"
        ),
        .testTarget(
            name: "PexipVideoFiltersTests",
            dependencies: [
                "PexipVideoFilters",
                "TestHelpers",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            exclude: ["Internal/__Snapshots__/"],
            resources: [
                .copy("Resources/testVideo.mp4"),
                .copy("Resources/testImage.jpg"),
            ]
        ),

        // MARK: - PexipScreenCapture

        .target(
            name: "PexipScreenCapture"
        ),
        .testTarget(
            name: "PexipScreenCaptureTests",
            dependencies: ["PexipScreenCapture", "TestHelpers"]
        ),

        // MARK: - TestHelpers

        .target(name: "TestHelpers", path: "Tests/TestHelpers"),
    ]
)
