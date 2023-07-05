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

import WebRTC
import PexipCore
import PexipMedia
import PexipScreenCapture

public final class WebRTCMediaFactory: MediaFactory {
    private let factory: RTCPeerConnectionFactory
    private let logger: Logger?

    // MARK: - Init

    public convenience init(logger: Logger? = DefaultLogger.mediaWebRTC) {
        self.init(factory: .defaultFactory(), logger: logger)
    }

    init(factory: RTCPeerConnectionFactory, logger: Logger? = nil) {
        self.factory = factory
        self.logger = logger
    }

    // MARK: - MediaFactory

    public func videoInputDevices() throws -> [MediaDevice] {
        let defaultDevice = AVCaptureDevice.default(for: .video)
        return AVCaptureDevice.videoCaptureDevices(withPosition: .unspecified)
            .sorted(by: { device1, _ in
                #if os(iOS)
                device1.position == .front
                #else
                device1.uniqueID == defaultDevice?.uniqueID
                #endif
            })
            .filter({ device in
                let isSuspended: Bool = {
                    if #available(iOS 14.0, *) {
                        return device.isSuspended
                    } else {
                        return false
                    }
                }()
                return device.isConnected && !isSuspended
            })
            .map({
                MediaDevice(
                    id: $0.uniqueID,
                    name: $0.localizedName,
                    mediaType: .video,
                    direction: .input
                )
            })
    }

    public func createLocalAudioTrack() -> LocalAudioTrack {
        let audioSource = factory.audioSource(with: nil)
        let audioTrack = factory.audioTrack(
            with: audioSource,
            trackId: UUID().uuidString.lowercased()
        )
        return WebRTCLocalAudioTrack(
            rtcTrack: audioTrack,
            logger: logger
        )
    }

    public func createCameraVideoTrack() -> CameraVideoTrack? {
        do {
            if let device = try videoInputDevices().first {
                return createCameraVideoTrack(device: device)
            }
        } catch {
            logger?.error("Failed to load video input devices: \(error)")
        }

        return nil
    }

    public func createCameraVideoTrack(device: MediaDevice) -> CameraVideoTrack {
        precondition(
            device.mediaType == .video,
            "Invalid capture device, must support video"
        )

        precondition(
            device.direction == .input,
            "Invalid capture device, must be input device"
        )

        guard let device = AVCaptureDevice(uniqueID: device.id) else {
            preconditionFailure("Cannot create AVCaptureDevice with given id: \(device.id)")
        }

        let videoSource = factory.videoSource()
        let videoProcessor = WebRTCVideoProcessor(videoSource: videoSource)
        let videoTrack = factory.videoTrack(
            with: videoSource,
            trackId: UUID().uuidString.lowercased()
        )
        let videoCapturer = RTCCameraVideoCapturer(delegate: videoProcessor)

        return WebRTCCameraVideoTrack(
            device: device,
            rtcTrack: videoTrack,
            processor: videoProcessor,
            capturer: videoCapturer
        )
    }

    #if os(iOS)

    public func createScreenMediaTrack(
        appGroup: String,
        broadcastUploadExtension: String,
        defaultVideoProfile: QualityProfile
    ) -> ScreenMediaTrack {
        let screenMediaCapturer = BroadcastScreenCapturer(
            appGroup: appGroup,
            broadcastUploadExtension: broadcastUploadExtension,
            defaultFps: defaultVideoProfile.fps
        )
        return createScreenMediaTrack(
            screenMediaCapturer: screenMediaCapturer,
            defaultVideoProfile: defaultVideoProfile
        )
    }

    #else

    public func createScreenMediaTrack(
        mediaSource: ScreenMediaSource,
        defaultVideoProfile: QualityProfile
    ) -> ScreenMediaTrack {
        let screenMediaCapturer = ScreenMediaSource.createCapturer(for: mediaSource)
        return createScreenMediaTrack(
            screenMediaCapturer: screenMediaCapturer,
            defaultVideoProfile: defaultVideoProfile
        )
    }

    #endif

    public func createMediaConnection(
        config: MediaConnectionConfig
    ) -> MediaConnection {
        WebRTCMediaConnection(
            config: config,
            factory: factory,
            logger: logger
        )
    }

    // MARK: - Private

    private func createScreenMediaTrack(
        screenMediaCapturer: ScreenMediaCapturer,
        defaultVideoProfile: QualityProfile
    ) -> ScreenMediaTrack {
        let videoSource = factory.videoSource(forScreenCast: true)
        let videoTrack = factory.videoTrack(
            with: videoSource,
            trackId: UUID().uuidString.lowercased()
        )
        let capturer = WebRTCScreenCapturer(
            videoSource: videoSource,
            mediaCapturer: screenMediaCapturer,
            defaultVideoProfile: defaultVideoProfile,
            logger: logger
        )
        return WebRTCScreenMediaTrack(rtcTrack: videoTrack, capturer: capturer)
    }
}
