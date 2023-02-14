// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

//
// Copyright 2022-2023 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
            name: "PexipRTC",
            targets: ["PexipRTC"]
        ),
        .library(
            name: "PexipMedia",
            targets: ["PexipMedia"]
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
            url: "https://github.com/pexip/webrtc-objc",
            exact: "105.0.0"
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
            dependencies: ["PexipCore"],
            plugins: [.swiftLint]
        ),
        .testTarget(
            name: "PexipInfinityClientTests",
            dependencies: ["PexipInfinityClient", "TestHelpers"],
            plugins: [.swiftLint]
        ),

        // MARK: - PexipRTC

        .target(
            name: "PexipRTC",
            dependencies: [
                "PexipMedia",
                .product(name: "WebRTC", package: "webrtc-objc")
            ],
            cSettings: [
               .unsafeFlags(["-w"])
            ],
            plugins: [.swiftLint]
        ),
        .testTarget(
            name: "PexipRTCTests",
            dependencies: ["PexipRTC"],
            plugins: [.swiftLint]
        ),

        // MARK: - PexipMedia

        .target(
            name: "PexipMedia",
            dependencies: ["PexipCore", "PexipScreenCapture"],
            plugins: [.swiftLint]
        ),
        .testTarget(
            name: "PexipMediaTests",
            dependencies: ["PexipMedia", "TestHelpers"],
            plugins: [.swiftLint]
        ),

        // MARK: -  PexipCore

        .target(
            name: "PexipCore",
            plugins: [.swiftLint]
        ),
        .testTarget(
            name: "PexipCoreTests",
            dependencies: ["PexipCore"],
            plugins: [.swiftLint]
        ),

        // MARK: - PexipVideoFilters

        .target(
            name: "PexipVideoFilters",
            dependencies: ["PexipCore"],
            plugins: [.swiftLint]
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
            plugins: [.swiftLint]
        ),

        // MARK: - PexipScreenCapture

        .target(
            name: "PexipScreenCapture",
            plugins: [.swiftLint]
        ),
        .testTarget(
            name: "PexipScreenCaptureTests",
            dependencies: ["PexipScreenCapture", "TestHelpers"],
            plugins: [.swiftLint]
        ),

        // MARK: - TestHelpers

        .target(
            name: "TestHelpers",
            path: "Tests/TestHelpers",
            plugins: [.swiftLint]
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

private extension Target.PluginUsage {
    static let swiftLint = Self.plugin(name: "SwiftLint")
}
