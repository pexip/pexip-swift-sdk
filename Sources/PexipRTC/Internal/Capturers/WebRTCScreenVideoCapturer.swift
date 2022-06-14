import WebRTC
import ImageIO
import PexipMedia
import PexipUtils

// MARK: - WebRTCScreenVideoCapturerErrorDelegate

protocol WebRTCScreenVideoCapturerErrorDelegate: AnyObject {
    func webRTCScreenVideoCapturer(
        _ capturer: WebRTCScreenVideoCapturer,
        didStopWithError error: Error?
    )
}

// MARK: - WebRTCScreenVideoCapturer

final class WebRTCScreenVideoCapturer: RTCVideoCapturer, ScreenVideoCapturerDelegate {
    weak var errorDelegate: WebRTCScreenVideoCapturerErrorDelegate?

    private let videoSource: RTCVideoSource
    private let capturer: ScreenVideoCapturer
    private let logger: Logger?
    private var profile: QualityProfile?

    // MARK: - Init

    init(
        videoSource: RTCVideoSource,
        capturer: ScreenVideoCapturer,
        logger: Logger?
    ) {
        self.videoSource = videoSource
        self.capturer = capturer
        self.logger = logger
        super.init(delegate: videoSource)
        capturer.delegate = self
    }

    // MARK: - Capture

    func startCapture(profile: QualityProfile) async throws {
        self.profile = profile
        try await capturer.startCapture(withFps: profile.fps)
        logger?.info("Screen capture did start.")
    }

    func stopCapture() async throws {
        try await capturer.stopCapture()
        logger?.info("Screen capture did stop.")
    }

    // MARK: - ScreenCapturerDelegate

    func screenVideoCapturer(
        _ capturer: ScreenVideoCapturer,
        didCaptureVideoFrame videoFrame: VideoFrame
    ) {
        if let profile = profile {
            let dimensions = downscaleVideoDimensions(
                from: videoFrame.dimensions,
                to: profile.dimensions
            )

            videoSource.adaptOutputFormat(
                toWidth: dimensions.width,
                height: dimensions.height,
                fps: Int32(profile.fps)
            )
        }

        let rtcPixelBuffer = RTCCVPixelBuffer(pixelBuffer: videoFrame.pixelBuffer)
        let rtcVideoFrame = RTCVideoFrame(
            buffer: rtcPixelBuffer.toI420(),
            rotation: videoFrame.orientation.rtcRotation,
            timeStampNs: Int64(videoFrame.elapsedTimeNs)
        )
        
        delegate?.capturer(self, didCapture: rtcVideoFrame)
    }

    func screenVideoCapturer(
        _ capturer: ScreenVideoCapturer,
        didStopWithError error: Error?
    ) {
        errorDelegate?.webRTCScreenVideoCapturer(self, didStopWithError: error)
    }

    // MARK: - Private

    private func downscaleVideoDimensions(
        from: CMVideoDimensions,
        to: CMVideoDimensions
    ) -> CMVideoDimensions {
        if from.height > to.height {
            let ratio = Float(from.height) / Float(from.width)
            let newHeight = to.height
            let newWidth = Int32((Float(newHeight) / ratio).rounded(.down))
            return CMVideoDimensions(width: newWidth, height: newHeight)
        } else if from.width > to.width {
            let ratio = Float(from.height) / Float(from.width)
            let newWidth = to.width
            let newHeight = Int32((Float(newWidth) * ratio).rounded(.down))
            return CMVideoDimensions(width: newWidth, height: newHeight)
        }

        return from
    }
}
