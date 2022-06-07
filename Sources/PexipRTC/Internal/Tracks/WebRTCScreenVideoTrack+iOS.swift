#if os(iOS)

import WebRTC
import PexipMedia

final class WebRTCScreenVideoTrack: WebRTCVideoTrack,
                                    ScreenVideoTrack,
                                    WebRTCScreenVideoCapturerErrorDelegate {
    let capturingStatus = CapturingStatus(isCapturing: false)

    private let capturer: WebRTCScreenVideoCapturer

    // MARK: - Init

    init(
        rtcTrack: RTCVideoTrack,
        capturer: WebRTCScreenVideoCapturer
    ) {
        self.capturer = capturer
        super.init(rtcTrack: rtcTrack)
        capturer.errorDelegate = self
    }

    deinit {
        stopCapture(withDelay: false)
    }

    // MARK: - ScreenVideoTrack

    func startCapture(profile: QualityProfile) throws {
        if capturingStatus.isCapturing {
            stopCapture()
        }

        isEnabled = true

        try capturer.startCapture(profile: profile)

        capturingStatus.isCapturing = true
    }

    func stopCapture() {
        stopCapture(withDelay: true)
    }

    // MARK: - WebRTCScreenVideoCapturerErrorDelegate

    func webRTCScreenVideoCapturer(
        _ capturer: WebRTCScreenVideoCapturer,
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

        func stop(track: WebRTCScreenVideoTrack?, capturer: WebRTCScreenVideoCapturer?) {
            try? capturer?.stopCapture()
            track?.renderEmptyFrame()
        }

        if withDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self, weak capturer] in
                stop(track: self, capturer: capturer)
            }
        } else {
            stop(track: self, capturer: capturer)
        }
    }
}

#endif
