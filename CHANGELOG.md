# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2022-06-27

### Added

- [SDK Documentation](https://pexip.github.io/pexip-swift-sdk)
- [Screen sharing on iOS](https://pexip.github.io/pexip-swift-sdk/sdk/documentation/pexipswiftsdk/iosscreensharing) with ReplayKit and Broadcast Upload Extensions
- [Screen sharing on macOS](https://pexip.github.io/pexip-swift-sdk/sdk/documentation/pexipswiftsdk/macosscreensharing)
- `MediaConnectionConfig`: add an option to enable DSCP
- Move bandwidth setting from `QualityProfile` to `MediaConnectionConfig`

### Changed

- **BREAKING**: rename public methods in `MediaConnection`, see [docs](https://pexip.github.io/pexip-swift-sdk/frameworks/ios/PexipMedia/documentation/pexipmedia/mediaconnection) for reference.

## [0.2.0] - 2022-05-12

### Added

- Introduce `MediaConnectionFactory` to create local media tracks without an instance of `MediaConnection`
- Update example projects

### Changed

- Use WebRTC M96

## [0.1.0] - 2022-05-06

### Added

- Initial release

[Unreleased]: https://github.com/pexip/pexip-swift-sdk/compare/0.3.0...HEAD
[0.3.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.3.0
[0.2.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.2.0
[0.1.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.1.0