#if os(macOS)

import WebRTC
import PexipMedia

final class WebRTCScreenVideoTrack: WebRTCVideoTrack, ScreenVideoTrack {
    let capturingStatus = CapturingStatus(isCapturing: false)

    private let videoSource: ScreenVideoSource
    private let capturer: WebRTCScreenVideoCapturer

    // MARK: - Init

    init(
        rtcTrack: RTCVideoTrack,
        videoSource: ScreenVideoSource,
        capturer: WebRTCScreenVideoCapturer
    ) {
        self.videoSource = videoSource
        self.capturer = capturer
        super.init(rtcTrack: rtcTrack)
    }

    deinit {
        stopCapture(withDelay: false)
    }

    // MARK: - ScreenVideoTrack

    func startCapture(
        withConfiguration configuration: ScreenCaptureConfiguration
    ) async throws {
        if capturingStatus.isCapturing {
            stopCapture()
        }

        isEnabled = true

        try await capturer.startCapture(
            videoSource: videoSource,
            configuration: configuration
        )

        capturingStatus.isCapturing = true
    }

    func stopCapture() {
        stopCapture(withDelay: true)
    }

    // MARK: - Private

    private func stopCapture(withDelay: Bool) {
        guard capturingStatus.isCapturing else {
            return
        }

        isEnabled = false
        capturingStatus.isCapturing = false

        func stop(capturer: WebRTCScreenVideoCapturer?) {
            Task { [weak self, weak capturer] in
                try await capturer?.stopCapture()
                self?.renderEmptyFrame()
            }
        }

        if withDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak capturer] in
                stop(capturer: capturer)
            }
        } else {
            stop(capturer: capturer)
        }
    }
}

#endif
