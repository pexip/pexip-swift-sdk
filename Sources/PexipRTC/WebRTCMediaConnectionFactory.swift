import WebRTC
import PexipUtils
import PexipMedia

public final class WebRTCMediaConnectionFactory: MediaConnectionFactory {
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
        let videoTrack = factory.videoTrack(
            with: videoSource,
            trackId: UUID().uuidString
        )
        let videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        return WebRTCCameraVideoTrack(
            device: device,
            rtcTrack: videoTrack,
            capturer: videoCapturer
        )
    }

    #if os(macOS)
    public func createScreenVideoTrack(
        videoSource: ScreenVideoSource
    ) -> ScreenVideoTrack {
        let screenVideoSource = videoSource
        let videoSource = factory.videoSource()
        let videoTrack = factory.videoTrack(
            with: videoSource,
            trackId: UUID().uuidString
        )
        let rtcScreenVideoCapturer = WebRTCScreenVideoCapturer(
            capturer: ScreenVideoSource.createCapturer(),
            logger: logger,
            delegate: videoSource
        )
        return WebRTCScreenVideoTrack(
            rtcTrack: videoTrack,
            videoSource: screenVideoSource,
            capturer: rtcScreenVideoCapturer
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
}
