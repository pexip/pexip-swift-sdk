# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] - 2022-09-13

### Added

- Make it possible to receive incoming calls with [Registration API](https://pexip.github.io/pexip-swift-sdk/sdk/documentation/pexipswiftsdk/registration)

### Changed
- Update WebRTC to M105
- Remove `PixipConference` framework, use [PexipInfinityClient](https://pexip.github.io/pexip-swift-sdk/frameworks/ios/PexipInfinityClient/documentation/pexipinfinityclient/) instead
- Rename `PexipUtils` framework to [PexipCore](https://pexip.github.io/pexip-swift-sdk/frameworks/ios/PexipCore/documentation/pexipcore/)
- Screen sharing: move functionality to a separate [PexipScreenCapture](https://pexip.github.io/pexip-swift-sdk/frameworks/ios/PexipScreenCapture/documentation/pexipscreencapture/) framework
- Video filters: move functionality to a separate [PexipVideoFilters](https://pexip.github.io/pexip-swift-sdk/frameworks/ios/PexipVideoFilters/documentation/pexipvideofilters/)
- DTMF APIs were moved to [MediaConnection](https://pexip.github.io/pexip-swift-sdk/frameworks/ios/PexipMedia/documentation/pexipmedia/mediaconnection/dtmf(signals:)) and [CallService](https://pexip.github.io/pexip-swift-sdk/frameworks/ios/PexipInfinityClient/documentation/pexipinfinityclient/callservice/dtmf(signals:token:))
- Various breaking changes in the public APIs, see the [Example project](https://github.com/pexip/pexip-swift-sdk/tree/main/Examples/Conference) for more info. 

## [0.4.0] - 2022-08-02

### Added

- [Video filters](https://pexip.github.io/pexip-swift-sdk/sdk/documentation/pexipswiftsdk/videofilters), e.g. background blur, virtual background, custom filters, etc.
- [Live captions](https://pexip.github.io/pexip-swift-sdk/sdk/documentation/pexipswiftsdk/livecaptions)
- [DTMF support](https://pexip.github.io/pexip-swift-sdk/frameworks/ios/PexipConference/documentation/pexipconference/conference/dtmf(signals:))

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

[Unreleased]: https://github.com/pexip/pexip-swift-sdk/compare/0.5.0...HEAD
[0.5.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.5.0
[0.4.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.4.0
[0.3.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.3.0
[0.2.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.2.0
[0.1.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.1.0