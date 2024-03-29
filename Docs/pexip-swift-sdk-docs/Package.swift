// swift-tools-version: 5.6

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
    name: "pexip-swift-sdk-docs",
    products: [
        .library(
            name: "PexipSwiftSDK",
            targets: ["PexipSwiftSDK"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-docc-plugin",
            branch: "1.0.0"
        )
    ],
    targets: [
        .target(
            name: "PexipSwiftSDK",
            dependencies: []
        ),
        .testTarget(
            name: "PexipSwiftSDKTests",
            dependencies: ["PexipSwiftSDK"]
        )
    ]
)
