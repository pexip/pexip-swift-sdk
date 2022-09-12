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
            name: "PexipVideoFilters",
            targets: ["PexipVideoFilters"]
        ),
        .library(
            name: "PexipScreenCapture",
            targets: ["PexipScreenCapture"]
        ),
        .library(
            name: "PexipCore",
            targets: ["PexipCore"]
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
        ),
    ],
    targets: [
        // MARK: - PexipInfinityClient

        .target(
            name: "PexipInfinityClient",
            dependencies: ["PexipCore"]
        ),
        .testTarget(
            name: "PexipInfinityClientTests",
            dependencies: ["PexipInfinityClient", "TestHelpers"]
        ),

        // MARK: - PexipMedia

        .target(
            name: "PexipMedia",
            dependencies: ["PexipCore", "PexipScreenCapture"]
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
                "PexipCore",
                .product(name: "WebRTC", package: "webrtc-ios-builds")
            ]
        ),
        .testTarget(
            name: "PexipRTCTests",
            dependencies: ["PexipRTC"]
        ),

        // MARK: -  PexipCore

        .target(
            name: "PexipCore"
        ),
        .testTarget(
            name: "PexipCoreTests",
            dependencies: ["PexipCore"]
        ),

        // MARK: - PexipVideoFilters

        .target(
            name: "PexipVideoFilters",
            dependencies: ["PexipCore"]
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

        .target(
            name: "TestHelpers",
            path: "Tests/TestHelpers",
            plugins: ["SwiftLint"]
        ),

        // MARK: - Plugins

        .binaryTarget(
             name: "SwiftLintBinary",
             url: "https://github.com/realm/SwiftLint/releases/download/0.48.0/SwiftLintBinary-macos.artifactbundle.zip",
             checksum: "9c255e797260054296f9e4e4cd7e1339a15093d75f7c4227b9568d63edddba50"
         ),

        .plugin(
            name: "SwiftLint",
            capability: .buildTool(),
            dependencies: [
                "SwiftLintBinary",
            ]
        )
    ]
)
