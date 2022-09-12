# Pexip Swift SDK for iOS and macOS

[![Swift](https://img.shields.io/badge/Swift-5.5_5.6-orange?style=flat-square)](https://img.shields.io/badge/Swift-5.5_5.6-Orange?style=flat-square)
[![Platforms](https://img.shields.io/badge/Platforms-iOS_macOS-yellowgreen?style=flat-square)](https://img.shields.io/badge/Platforms-iOS_macOS-yellowgreen?style=flat-square)
[![CocoaPods Compatible](https://img.shields.io/badge/CocoaPods-compatible-green?style=flat-square)](https://img.shields.io/badge/CocoaPods-compatible-green?style=flat-square)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)

**Pexip Swift SDK** is a collection of frameworks for self hosted [Pexip Infinity](https://docs.pexip.com/admin/admin_intro.htm) installations that enables customers to build bespoke applications for Apple platforms or add Pexip to existing mobile or desktop experiences and workflows.

- [Features](#features)
- [Products](#products)
- [Requirements](#requirements)
- [Installation](#installation)
- [Documentation](https://pexip.github.io/pexip-swift-sdk/sdk/documentation/pexipswiftsdk/)
- [Examples](#examples)
- [License](#license)

## Features

- Built upon the [Pexip Client REST API for Infinity](https://docs.pexip.com/api_client/api_rest.htm)
- Uses media signaling with [WebRTC](https://webrtc.org)
- Granulated into multiple libraries in order to be flexible and future proof. Pexip might provide other 
media signaling technologies in the future, or Infinity might be interchanged with the next generation APIs from Pexip at some point.

## Products

- **PexipInfinityClient** - a fluent client for Pexip Infinity REST API v2, conference controls, conference events, media signaling and token refreshing.
- **PexipRTC** - Pexip WebRTC-based media stack for sending and receiving video streams
- **PexipMedia** - core components for working with audio and video
- **PexipVideoFilters** - a set of built-in video filters ready to use in your video conferencing app (background blur, background replacement, etc)
- **PexipScreenCapture** - high level APIs for screen capture on iOS and macOS
- **PexipCore** - extensions, utilities and shared components
- **WebRTC** - WebRTC binaries for Apple platforms

## Requirements

- iOS 13.0+
- macOS 10.15+
- Swift 5.5 with structured concurrency support
- Xcode 13

## Installation

### Swift Package Manager

To add a package dependency to your Xcode project, select File > Add Packages and enter 
`https://github.com/pexip/pexip-swift-sdk` as a repository URL.

You can also add the following dependency to your `Package.swift` file:
```swift
import PackageDescription

let package = Package(
    name: "MyLibrary",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/pexip/pexip-swift-sdk", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "MyLibrary",
            dependencies: [
                .product(name: "PexipInfinityClient", package: "pexip-swift-sdk"),
                .product(name: "PexipRTC", package: "pexip-swift-sdk"),
                // ...
            ],
        ),
    ]
)
```

### CocoaPods

```ruby
source 'https://github.com/pexip/pexip-pod-specs.git'

pod 'PexipInfinityClient'
pod 'PexipRTC'
```

### Manually

- Download the archives from the [GitHub releases](https://github.com/pexip/pexip-swift-sdk/releases)
- Add the xcframeworks as embedded frameworks to your target in Xcode

## Examples

- Check [Swift Package Manager example app](https://github.com/pexip/pexip-swift-sdk/tree/main/Examples/Conference) to learn how to integrate **Pexip Swift SDK** in your app.

- Check [Video Filters example app](https://github.com/pexip/pexip-swift-sdk/tree/main/Examples/VideoFilters) to learn how to apply various video filters and use [ML Kit's Selfie Segmentation API](https://developers.google.com/ml-kit) instead of default [Vision Person Segmentation](https://developer.apple.com/documentation/vision/vngeneratepersonsegmentationrequest), which is available only on iOS 15.0+ and macOS 12.0+.

- Check [CocoaPods example app](https://github.com/pexip/pexip-swift-sdk/tree/main/Examples/CocoaPods) to 
see how to install **Pexip Swift SDK** with Cocoa Pods.

- [SDK documentation and API reference](https://pexip.github.io/pexip-swift-sdk)

## WIP

**Pexip Swift SDK** is still in active development, there will be breaking changes until we reach v1.0.
If you have any questions about the SDK please contact your Pexip representative.

## License

**Pexip Swift SDK** is released under the Apache Software License, version 1.1. 
See [LICENSE](https://github.com/pexip/pexip-swift-sdk/blob/main/LICENSE) for details.
