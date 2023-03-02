# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.7.0] - 2023-03-02

### Added
- Screen capture:
  - Make it possible to start capture session not only from the app, but also from the iOS control center while on an active call
  - Introduce keep-alive time in order to stop broadcast extension, started from the iOS control center, when there are no active calls
  - Add more broadcast error types and the API to finish screen capture session with reason, such as callEnded or presentationStolen. See `ScreenMediaTrack.stopCapture(reason:)`

### Changed
- Screen capture: change IPC on iOS from Unix domain sockets to memory-mapped file
- Deprecate `ScreenMediaTrackFactory.createScreenMediaTrack(appGroup:broadcastUploadExtension)` on iOS, use `createScreenMediaTrack(appGroup:broadcastUploadExtension:defaultVideoProfile)` instead
- Deprecate `ScreenMediaTrackFactory.createScreenMediaTrack(mediaSource)` on macOS, use `createScreenMediaTrack(mediaSource:defaultVideoProfile)` instead
- Deprecate `ScreenMediaCapturer.startCapture(atFps:outputDimensions)` on iOS, use `startCapture(atFps:)` instead

### Fixed
- Adapt WebRTC output format on iOS

## [0.6.0] - 2023-01-18

### Added

- Make it possible to participate in [direct media calls](https://pexip.github.io/pexip-swift-sdk/sdk/documentation/pexipswiftsdk/directmedia)
- New `VideoContentMode.fit` to fit the size of the video view by maintaining the original aspect ratio (could be used to support portrait video on direct media call)
- Send chat messages via WebRTC data channel when on direct media call 
- Calculate secure check code on each send/receive of an SDP offer/answer, see `MediaConnection.secureCheckCode`
- Load conference themes, accessible via `Conference.splashScreens` property or `splashScreen` event
- New conference events:
  - `splashScreen` for local rendering of splash images and messages 
  - `peerDisconnected` for restarting media connection during direct media call
  - `refer` for tranferring direct media call to transcoded call and back

### Changed
- **BREAKING**: Use String instead of UUID for various types in `PexipInfinityClient`
- **BREAKING**: add kind property to `IceServer` struct to differentiate TURN and STUN servers
- **BREAKING**: `CameraVideoTrackFactory`: use new `MediaDevice` type instead of `AVCaptureDevice`
- **BREAKING**: `CameraVideoTrack.toggleCamera` doesn't return camera position anymore
- **BREAKING**: `SignalingChannel.sendOffer` now returns optional SDP string
- More changes in the public APIs of `PexipInfinityClient` and `PexipMedia` frameworks, see the [Example project](https://github.com/pexip/pexip-swift-sdk/tree/main/Examples/Conference) for more info. 

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

[Unreleased]: https://github.com/pexip/pexip-swift-sdk/compare/0.7.0...HEAD
[0.7.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.7.0
[0.6.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.6.0
[0.5.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.5.0
[0.4.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.4.0
[0.3.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.3.0
[0.2.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.2.0
[0.1.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.1.0