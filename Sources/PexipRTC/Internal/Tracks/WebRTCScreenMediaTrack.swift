import WebRTC
import PexipMedia

final class WebRTCScreenMediaTrack: WebRTCVideoTrack,
                                    ScreenMediaTrack,
                                    WebRTCScreenCapturerErrorDelegate {
    let capturingStatus = CapturingStatus(isCapturing: false)
    private let capturer: WebRTCScreenCapturer

    // MARK: - Init

    init(
        rtcTrack: RTCVideoTrack,
        capturer: WebRTCScreenCapturer
    ) {
        self.capturer = capturer
        super.init(rtcTrack: rtcTrack)
        capturer.errorDelegate = self
    }

    deinit {
        stopCapture(withDelay: false)
    }

    // MARK: - ScreenMediaTrack

    func startCapture() async throws {
        try await startCapture(withVideoProfile: .presentationHigh)
    }

    func startCapture(withVideoProfile videoProfile: QualityProfile) async throws {
        if capturingStatus.isCapturing {
            stopCapture()
        }

        isEnabled = true

        try await capturer.startCapture(withVideoProfile: videoProfile)

        capturingStatus.isCapturing = true
    }

    func stopCapture() {
        stopCapture(withDelay: true)
    }

    // MARK: - WebRTCScreenCapturerErrorDelegate

    func webRTCScreenCapturer(
        _ capturer: WebRTCScreenCapturer,
        didStopWithError error: Error?
    ) {
        isEnabled = false
        capturingStatus.isCapturing = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.renderEmptyFrame()
        }
    }

    // MARK: - Private

    private func stopCapture(withDelay: Bool) {
        guard capturingStatus.isCapturing else {
            return
        }

        isEnabled = false
        capturingStatus.isCapturing = false

        func stop(capturer: WebRTCScreenCapturer?) {
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
