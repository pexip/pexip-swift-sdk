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
        AVCaptureDevice.videoCaptureDevices(withPosition: .unspecified)
            .sorted(by: { device1, _ in
                device1.position == .front
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
            trackId: UUID().uuidString
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
            trackId: UUID().uuidString
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
        broadcastUploadExtension: String
    ) -> ScreenMediaTrack {
        let screenMediaCapturer = BroadcastScreenCapturer(
            appGroup: appGroup,
            broadcastUploadExtension: broadcastUploadExtension
        )
        return createScreenMediaTrack(screenMediaCapturer: screenMediaCapturer)
    }

    #else

    public func createScreenMediaTrack(
        mediaSource: ScreenMediaSource
    ) -> ScreenMediaTrack {
        let screenMediaCapturer = ScreenMediaSource.createCapturer(for: mediaSource)
        return createScreenMediaTrack(screenMediaCapturer: screenMediaCapturer)
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
        screenMediaCapturer: ScreenMediaCapturer
    ) -> ScreenMediaTrack {
        let videoSource = factory.videoSource(forScreenCast: true)
        let videoTrack = factory.videoTrack(
            with: videoSource,
            trackId: UUID().uuidString
        )
        let capturer = WebRTCScreenCapturer(
            videoSource: videoSource,
            mediaCapturer: screenMediaCapturer,
            logger: logger
        )
        return WebRTCScreenMediaTrack(rtcTrack: videoTrack, capturer: capturer)
    }
}
