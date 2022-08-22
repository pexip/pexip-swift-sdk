import WebRTC
import ImageIO
import PexipMedia
import PexipUtils
import PexipScreenCapture

// MARK: - WebRTCScreenCapturerErrorDelegate

protocol WebRTCScreenCapturerErrorDelegate: AnyObject {
    func webRTCScreenCapturer(
        _ capturer: WebRTCScreenCapturer,
        didStopWithError error: Error?
    )
}

// MARK: - WebRTCScreenCapturer

final class WebRTCScreenCapturer: RTCVideoCapturer, ScreenMediaCapturerDelegate {
    weak var errorDelegate: WebRTCScreenCapturerErrorDelegate?

    private let videoSource: RTCVideoSource
    private let capturer: ScreenMediaCapturer
    private let logger: Logger?
    private var videoProfile: QualityProfile?
    private var startTimeNs: UInt64?

    // MARK: - Init

    init(
        videoSource: RTCVideoSource,
        mediaCapturer: ScreenMediaCapturer,
        logger: Logger?
    ) {
        self.videoSource = videoSource
        self.capturer = mediaCapturer
        self.logger = logger
        super.init(delegate: videoSource)
        capturer.delegate = self
    }

    // MARK: - Capture

    func startCapture(withVideoProfile videoProfile: QualityProfile) async throws {
        self.videoProfile = videoProfile
        try await capturer.startCapture(
            atFps: videoProfile.fps,
            outputDimensions: videoProfile.dimensions
        )
        logger?.info("Screen capture did start.")
    }

    func stopCapture() async throws {
        try await capturer.stopCapture()
        logger?.info("Screen capture did stop.")
    }

    // MARK: - ScreenMediaCapturerDelegate

    func screenMediaCapturer(
        _ capturer: ScreenMediaCapturer,
        didCaptureVideoFrame videoFrame: VideoFrame
    ) {
        let cropDimensions = videoFrame.contentDimensions
        var adaptedDimensions = cropDimensions

        if let videoProfile = videoProfile {
            adaptedDimensions = videoFrame.adaptedContentDimensions(
                to: videoProfile.dimensions
            )

            videoSource.adaptOutputFormat(
                toWidth: adaptedDimensions.width,
                height: adaptedDimensions.height,
                fps: Int32(videoProfile.fps)
            )
        }

        let rtcPixelBuffer = RTCCVPixelBuffer(
            pixelBuffer: videoFrame.pixelBuffer,
            adaptedWidth: adaptedDimensions.width,
            adaptedHeight: adaptedDimensions.height,
            cropWidth: cropDimensions.width,
            cropHeight: cropDimensions.height,
            cropX: videoFrame.contentX,
            cropY: videoFrame.contentY
        )

        startTimeNs = startTimeNs ?? videoFrame.displayTimeNs

        let rtcVideoFrame = RTCVideoFrame(
            buffer: rtcPixelBuffer.toI420(),
            rotation: videoFrame.orientation.rtcRotation,
            timeStampNs: Int64(videoFrame.displayTimeNs - startTimeNs!)
        )

        delegate?.capturer(self, didCapture: rtcVideoFrame)
    }

    func screenMediaCapturer(
        _ capturer: ScreenMediaCapturer,
        didStopWithError error: Error?
    ) {
        errorDelegate?.webRTCScreenCapturer(self, didStopWithError: error)
    }
}
