#if os(macOS)

import WebRTC
import PexipMedia
import PexipUtils

final class WebRTCScreenVideoCapturer: RTCVideoCapturer, ScreenVideoCapturerDelegate {
    private let capturer: ScreenVideoCapturer
    private let logger: Logger?

    // MARK: - Init

    init(
        capturer: ScreenVideoCapturer,
        logger: Logger?,
        delegate: RTCVideoCapturerDelegate
    ) {
        self.capturer = capturer
        self.logger = logger
        super.init(delegate: delegate)
        capturer.delegate = self
    }

    // MARK: - Capture

    func startCapture(
        videoSource: ScreenVideoSource,
        configuration: ScreenCaptureConfiguration
    ) async throws {
        try await capturer.startCapture(
            videoSource: videoSource,
            configuration: configuration
        )
    }

    func stopCapture() async throws {
        try await capturer.stopCapture()
    }

    // MARK: - ScreenCapturerDelegate

    func screenVideoCapturer(
        _ capturer: ScreenVideoCapturer,
        didCaptureVideoFrame videoFrame: VideoFrame
    ) {
        let rtcPixelBuffer = RTCCVPixelBuffer(pixelBuffer: videoFrame.pixelBuffer)
        let rtcVideoFrame = RTCVideoFrame(
            buffer: rtcPixelBuffer,
            rotation: ._0,
            timeStampNs: Int64(videoFrame.elapsedTimeNs)
        )
        delegate?.capturer(self, didCapture: rtcVideoFrame)
    }

    func screenVideoCapturerDidStop(_ capturer: ScreenVideoCapturer) {
        logger?.warn("ScreenVideoCapturer did stop")
    }
}

#endif
