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
            exact: "115.0.5790"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
            from: "1.9.0"
        )
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

        // MARK: - PexipRTC

        .target(
            name: "PexipRTC",
            dependencies: [
                "PexipMedia",
                .product(name: "WebRTC", package: "webrtc-objc")
            ]
        ),
        .testTarget(
            name: "PexipRTCTests",
            dependencies: ["PexipRTC"]
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

        // MARK: - PexipCore

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
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            exclude: ["Internal/__Snapshots__/"],
            resources: [
                .copy("Resources/testVideo.mp4"),
                .copy("Resources/testImage.jpg")
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
            path: "Tests/TestHelpers"
        )
    ]
)
