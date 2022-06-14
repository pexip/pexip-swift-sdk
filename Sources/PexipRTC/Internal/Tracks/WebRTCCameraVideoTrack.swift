import WebRTC
import PexipMedia

final class WebRTCCameraVideoTrack: WebRTCVideoTrack, CameraVideoTrack {
    let capturingStatus = CapturingStatus(isCapturing: false)
    var qualityProfile: QualityProfile?

    private var currentDevice: AVCaptureDevice
    private let capturer: RTCCameraVideoCapturer
    private let permission: MediaCapturePermission

    // MARK: - Init

    init(
        device: AVCaptureDevice,
        rtcTrack: RTCVideoTrack,
        capturer: RTCCameraVideoCapturer,
        permission: MediaCapturePermission = .video
    ) {
        self.currentDevice = device
        self.capturer = capturer
        self.permission = permission
        super.init(rtcTrack: rtcTrack)
    }

    deinit {
        stopCapture(withDelay: false)
    }

    // MARK: - CameraVideoTrack

    func startCapture() async throws {
        try await startCapture(profile: .medium)
    }

    func startCapture(profile: QualityProfile) async throws {
        let status = await permission.requestAccess()

        if let error = MediaCapturePermissionError(status: status) {
            throw error
        }

        if capturingStatus.isCapturing {
            stopCapture()
        }

        guard let format = profile.bestFormat(
            from: RTCCameraVideoCapturer.supportedFormats(for: currentDevice),
            formatDescription: \.formatDescription
        ) else {
            return
        }

        guard let fps = profile.bestFrameRate(
            from: format.videoSupportedFrameRateRanges,
            maxFrameRate: \.maxFrameRate
        ) else {
            return
        }

        isEnabled = true

        try await capturer.startCapture(
            with: currentDevice,
            format: format,
            fps: Int(fps)
        )

        qualityProfile = profile
        capturingStatus.isCapturing = true
    }

    func stopCapture() {
        stopCapture(withDelay: true)
    }

    #if os(iOS)
    @discardableResult
    func toggleCamera() async throws -> AVCaptureDevice.Position {
        guard let newDevice = AVCaptureDevice.videoCaptureDevice(
            withPosition: currentDevice.position == .front ? .back : .front
        ) else {
            return currentDevice.position
        }

        // Restart the video capturing using another camera
        currentDevice = newDevice
        stopCapture()

        if let qualityProfile = qualityProfile {
            try await startCapture(profile: qualityProfile)
        } else {
            try await startCapture()
        }

        return currentDevice.position
    }
    #endif

    // MARK: - Private

    private func stopCapture(withDelay: Bool) {
        guard capturingStatus.isCapturing else {
            return
        }

        isEnabled = false
        capturingStatus.isCapturing = false

        func stop(capturer: RTCCameraVideoCapturer?) {
            capturer?.stopCapture { [weak self] in
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
