// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let isDevelopment = true
let sdkName = isDevelopment ? "pexip-swift-sdk-sources" : "pexip-swift-sdk"
let sdkPackage: Package.Dependency = isDevelopment
    ? .package(path: "../../../../\(sdkName)")
    : .package(url: "https://github.com/pexip/\(sdkName)", exact: .init(0, 4, 0))

let package = Package(
    name: "Dependencies",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "App",
            targets: ["App"]
        ),
        .library(
            name: "BroadcastExtension",
            targets: ["BroadcastExtension"]
        )
    ],
    dependencies: [
        sdkPackage
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "PexipUtils", package: sdkName),
                .product(name: "PexipMedia", package: sdkName),
                .product(name: "PexipInfinityClient", package: sdkName),
                .product(name: "PexipRTC", package: sdkName),
                .product(name: "PexipConference", package: sdkName),
                .product(name: "PexipVideoFilters", package: sdkName)
            ]
        ),
        .target(
            name: "BroadcastExtension",
            dependencies: [
                .product(name: "PexipUtils", package: sdkName),
                .product(name: "PexipMedia", package: sdkName)
            ]
        )
    ]
)
