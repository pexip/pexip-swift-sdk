import WebRTC
import PexipMedia
import PexipCore

final class WebRTCCameraVideoTrack: WebRTCVideoTrack, CameraVideoTrack {
    let capturingStatus = CapturingStatus(isCapturing: false)
    var videoProfile: QualityProfile?
    var videoFilter: VideoFilter? {
        didSet {
            processor.setVideoFilter(videoFilter)
        }
    }

    private var currentDevice: AVCaptureDevice
    private let processor: WebRTCVideoProcessor
    private let capturer: RTCCameraVideoCapturer
    private let permission: MediaCapturePermission

    // MARK: - Init

    init(
        device: AVCaptureDevice,
        rtcTrack: RTCVideoTrack,
        processor: WebRTCVideoProcessor,
        capturer: RTCCameraVideoCapturer,
        permission: MediaCapturePermission = .video
    ) {
        self.currentDevice = device
        self.processor = processor
        self.capturer = capturer
        self.permission = permission
        super.init(rtcTrack: rtcTrack)
    }

    deinit {
        stopCapture(withDelay: false)
    }

    // MARK: - CameraVideoTrack

    func startCapture() async throws {
        try await startCapture(withVideoProfile: .medium)
    }

    func startCapture(withVideoProfile videoProfile: QualityProfile) async throws {
        let status = await permission.requestAccess()

        if let error = MediaCapturePermissionError(status: status) {
            throw error
        }

        if capturingStatus.isCapturing {
            stopCapture()
        }

        guard let format = videoProfile.bestFormat(
            from: RTCCameraVideoCapturer.supportedFormats(for: currentDevice),
            formatDescription: \.formatDescription
        ) else {
            return
        }

        guard let fps = videoProfile.bestFrameRate(
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

        self.videoProfile = videoProfile
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

        if let videoProfile = videoProfile {
            try await startCapture(withVideoProfile: videoProfile)
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
