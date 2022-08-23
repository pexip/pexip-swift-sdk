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
        ),
    ],
    targets: [
        // MARK: - PexipConference

        .target(
            name: "PexipConference",
            dependencies: ["PexipInfinityClient", "PexipMedia"],
            plugins: [.swiftlint]
        ),
        .testTarget(
            name: "PexipConferenceTests",
            dependencies: ["PexipConference"],
            plugins: [.swiftlint]
        ),

        // MARK: - PexipInfinityClient

        .target(
            name: "PexipInfinityClient",
            dependencies: ["PexipUtils"],
            plugins: [.swiftlint]
        ),
        .testTarget(
            name: "PexipInfinityClientTests",
            dependencies: ["PexipInfinityClient"],
            plugins: [.swiftlint]
        ),

        // MARK: - PexipMedia

        .target(
            name: "PexipMedia",
            dependencies: ["PexipScreenCapture"],
            plugins: [.swiftlint]
        ),
        .testTarget(
            name: "PexipMediaTests",
            dependencies: ["PexipMedia", "TestHelpers"],
            plugins: [.swiftlint]
        ),

        // MARK: - PexipRTC

        .target(
            name: "PexipRTC",
            dependencies: [
                "PexipMedia",
                "PexipUtils",
                .product(name: "WebRTC", package: "webrtc-ios-builds")
            ],
            plugins: [.swiftlint]
        ),
        .testTarget(
            name: "PexipRTCTests",
            dependencies: ["PexipRTC"],
            plugins: [.swiftlint]
        ),

        // MARK: -  PexipUtils

        .target(
            name: "PexipUtils",
            plugins: [.swiftlint]
        ),
        .testTarget(
            name: "PexipUtilsTests",
            dependencies: ["PexipUtils"],
            plugins: [.swiftlint]
        ),

        // MARK: - PexipVideoFilters

        .target(
            name: "PexipVideoFilters",
            plugins: [.swiftlint]
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
            ],
            plugins: [.swiftlint]
        ),

        // MARK: - PexipScreenCapture

        .target(
            name: "PexipScreenCapture",
            plugins: [.swiftlint]
        ),
        .testTarget(
            name: "PexipScreenCaptureTests",
            dependencies: ["PexipScreenCapture", "TestHelpers"],
            plugins: [.swiftlint]
        ),

        // MARK: - TestHelpers

        .target(
            name: "TestHelpers",
            path: "Tests/TestHelpers",
            plugins: [.swiftlint]
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

extension Target.PluginUsage {
    static let swiftlint = Target.PluginUsage(stringLiteral: "SwiftLint")
}
