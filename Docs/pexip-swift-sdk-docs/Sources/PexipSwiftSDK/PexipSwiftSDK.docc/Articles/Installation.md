# Installation

Integrate Pexip Swift SDK into your project using Swift Package Manager, CocoaPods or manually.

## Requirements

- iOS 13.0+
- macOS 10.15+
- Swift 5.5 with structured concurrency support
- Xcode 13
- Pexip Infinity v29 and higher

## Swift Package Manager

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

## CocoaPods

```ruby
source 'https://github.com/pexip/pexip-pod-specs.git'

pod 'PexipInfinityClient'
pod 'PexipRTC'
```

## Manually

- Download the archives from the [GitHub releases](https://github.com/pexip/pexip-swift-sdk/releases)
- Add the xcframeworks as embedded frameworks to your target in Xcode
