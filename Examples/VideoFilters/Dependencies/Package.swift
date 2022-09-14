// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let isDevelopment = false
let sdkName = isDevelopment ? "pexip-swift-sdk-sources" : "pexip-swift-sdk"
let sdkPackage: Package.Dependency = isDevelopment
    ? .package(path: "../../../../\(sdkName)")
    : .package(path: "../../..")

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
        )
    ],
    dependencies: [
        sdkPackage
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "PexipCore", package: sdkName),
                .product(name: "PexipMedia", package: sdkName),
                .product(name: "PexipRTC", package: sdkName),
                .product(name: "PexipVideoFilters", package: sdkName)
            ]
        )
    ]
)
