import WebRTC
import PexipMedia
import PexipScreenCapture

final class WebRTCScreenMediaTrack: WebRTCVideoTrack,
                                    ScreenMediaTrack,
                                    WebRTCScreenCapturerDelegate {
    let capturingStatus = CapturingStatus(isCapturing: false)
    private let capturer: WebRTCScreenCapturer
    private let defaultVideoProfile: QualityProfile

    // MARK: - Init

    init(
        rtcTrack: RTCVideoTrack,
        capturer: WebRTCScreenCapturer,
        defaultVideoProfile: QualityProfile = .presentationHigh
    ) {
        self.capturer = capturer
        self.defaultVideoProfile = defaultVideoProfile
        super.init(rtcTrack: rtcTrack)
        capturer.capturerDelegate = self
    }

    deinit {
        stopCapture(withDelay: false, reason: nil)
    }

    // MARK: - ScreenMediaTrack

    func startCapture() async throws {
        try await startCapture(withVideoProfile: defaultVideoProfile)
    }

    func startCapture(withVideoProfile videoProfile: QualityProfile) async throws {
        if capturingStatus.isCapturing {
            stopCapture()
        }

        try await capturer.startCapture(withVideoProfile: videoProfile)

        #if os(macOS)
        setIsCapturing(true)
        #endif
    }

    func stopCapture() {
        stopCapture(reason: nil)
    }

    func stopCapture(reason: ScreenCaptureStopReason?) {
        stopCapture(withDelay: true, reason: reason)
    }

    // MARK: - WebRTCScreenCapturerDelegate

    #if os(iOS)

    func webRTCScreenCapturerDidStart(_ capturer: WebRTCScreenCapturer) {
        setIsCapturing(true)
    }

    #endif

    func webRTCScreenCapturer(
        _ capturer: WebRTCScreenCapturer,
        didStopWithError error: Error?
    ) {
        setIsCapturing(false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.renderEmptyFrame()
        }
    }

    // MARK: - Private

    private func setIsCapturing(_ isCapturing: Bool) {
        isEnabled = isCapturing
        capturingStatus.isCapturing = isCapturing
    }

    private func stopCapture(withDelay: Bool, reason: ScreenCaptureStopReason?) {
        guard capturingStatus.isCapturing else {
            return
        }

        setIsCapturing(false)

        func stop(capturer: WebRTCScreenCapturer?) {
            Task { [weak self, weak capturer] in
                try await capturer?.stopCapture(reason: reason)
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
