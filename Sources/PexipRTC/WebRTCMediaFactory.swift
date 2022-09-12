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

    // MARK: - MediaConnectionFactory

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
        func device(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
            AVCaptureDevice.videoCaptureDevice(withPosition: position)
        }

        guard let device = device(position: .front)
            ?? device(position: .back)
            ?? AVCaptureDevice.default(for: .video)
        else {
            return nil
        }

        return createCameraVideoTrack(device: device)
    }

    public func createCameraVideoTrack(
        device: AVCaptureDevice
    ) -> CameraVideoTrack {
        precondition(
            device.hasMediaType(.video),
            "Invalid capture device, must support video"
        )

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
