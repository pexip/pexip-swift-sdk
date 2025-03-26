# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## Added
- `MediaFactory.audioSession` to use instead of deprecated `AudioSession.shared`

# [0.10.1] - 2024-03-26

### Fixed
- Fix consistency issues with video captured using ReplayKit on iOS 16+ from a broadcast extension

# [0.10.0] - 2024-10-09

### Added
- Support audio in screen capture
- Make it possible to set preferred aspect ratio

## Changed
- `MediaFactory.audioSession` to use instead of deprecated `AudioSession.shared`

### Fixed
- Fix audio configuration for screen capture
- Don't check for host on mute/unmute
- Support cancellation in DNS lookup
- Use different audio session mode for audio and video calls

## Removed
- Remove various deprecated methods and types


## [0.9.0] - 2023-10-08

### Added
- New `AudioSession` class for configuring audio on iOS
- New customization options for `VideoComponent`: background color, corner radius
- Sort SRV records according to RFC 2782 specs

## Changed
- **BREAKING**: `MediaConnection.secureCheckCode` is now a publisher
- **BREAKING**: All functions in `MediaConnection` are now async
- Update WebRTC to M115
- Make it possible to create `WebRTCMediaFactory` with video encoder and decoder factories
- Use `RTCDefaultVideoEncoderFactory` and `RTCDefaultVideoDecoderFactory` as default factories on all platforms

### Fixed
- Fix `DNSServiceProcessResult` crash
- Fix Xcode 15 warnings
- Fall back to `.invalidPin` error on 403
- Fix creating conference address with uri

## Removed
- Remove various deprecated methods and types

## [0.8.0] - 2023-08-03

### Added
- `VideoComponent` can be created with custom `setRenderer` closure
- Support external cameras on macOS
- `ConferenceAddress` can be created with alias and host with no extra validation
- `MediaConnection.receiveMainRemoteAudio` and `MediaConnection.receiveMainRemoteVideo` to enable remote audio/video
- `MediaConnection.setMainDegradationPreference` and `MediaConnection.setPresentationDegradationPreference` that let one specify the desired behavior in low bandwidth conditions
- `MediaConnection.setMaxBitrate` that controls maximum bitrate for each video stream

### Changed
- `NodeResolver` now returns a host name instead of IP adress if A-record is found 
(fixes the issue with a certificate mismatch when the certificate is not configured to allow multi-domain)
- Don't stop video capture on switching between front and back cameras in `WebRTCCameraVideoTrack`
- Use default WebRTC bundle policy
- Print a warning if Infinity version prior to v29 is detected. **This will be a hard requirement in Q4 2023**
- `ConferenceAlias` is renamed to `ConferenceAddress`
- `DeviceAlias` is renamed to `DeviceAddress`
- `ack` is now called later in the call setup phase
- **BREAKING**: `MediaConnection.setMainAudioTrack` and `MediaConnection.setMainVideoTrack` are now throwing functions, and no longer enable remote audio/video by default. Please use `MediaConnection.receiveMainRemoteAudio` and `MediaConnection.receiveMainRemoteVideo` to enable them.

### Fixed
- Prevent data races when reading/writing to arrays with ice candidates in `WebRTCMediaConnection`
- Filter out windows without bundle ID in `ScreenMediaSourceEnumerator` on macOS

## Removed
- Removed various deprecated methods

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

[Unreleased]: https://github.com/pexip/pexip-swift-sdk/compare/0.10.1...HEAD
[0.10.1]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.10.1
[0.10.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.10.0
[0.9.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.9.0
[0.8.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.8.0
[0.7.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.7.0
[0.6.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.6.0
[0.5.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.5.0
[0.4.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.4.0
[0.3.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.3.0
[0.2.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.2.0
[0.1.0]: https://github.com/pexip/pexip-swift-sdk/releases/tag/0.1.0
