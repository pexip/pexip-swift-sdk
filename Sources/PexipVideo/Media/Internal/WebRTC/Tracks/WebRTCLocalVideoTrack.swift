import WebRTC

final class WebRTCLocalVideoTrack: LocalVideoTrackProtocol {
    var isEnabled: Bool {
        get { videoTrack.isEnabled }
        set {
            if videoTrack.isEnabled != newValue {
                setEnabled(newValue)
            }
        }
    }

    private weak var trackManager: RTCTrackManager?
    private let capturer: RTCCameraVideoCapturer
    private let qualityProfile: QualityProfile
    private var trackSender: RTCRtpSender?
    @MainActor private let videoTrack: WebRTCVideoTrack
    @MainActor private var cameraPosition: AVCaptureDevice.Position = .front

    // MARK: - Init

    init(
        factory: RTCPeerConnectionFactory,
        trackManager: RTCTrackManager,
        qualityProfile: QualityProfile,
        streamId: String
    ) {
        let videoSource = factory.videoSource()
        let track = factory.videoTrack(with: videoSource, trackId: UUID().uuidString)
        track.isEnabled = false

        self.videoTrack = WebRTCVideoTrack(track: track)
        self.capturer = RTCCameraVideoCapturer(delegate: videoSource)
        self.trackSender = trackManager.add(track, streamIds: [streamId])
        self.trackManager = trackManager
        self.qualityProfile = qualityProfile
    }

    deinit {
        if let trackSender = trackSender {
            _ = trackManager?.removeTrack(trackSender)
        }

        if videoTrack.isEnabled {
            videoTrack.isEnabled = false
            capturer.stopCapture { [weak videoTrack] in
                videoTrack?.renderEmptyFrame()
            }
        }
    }

    // MARK: - Internal methods

    func render(to view: VideoView, aspectFit: Bool) {
        videoTrack.render(to: view, aspectFit: aspectFit)
    }

    func toggleCamera() {
        guard isEnabled else {
            return
        }

        Task { @MainActor in
            cameraPosition = cameraPosition == .front ? .back : .front
            // Restart the video capturing using another camera
            try await stopCapture()
            try await startCapture()
        }
    }

    // MARK: - Private methods

    private func setEnabled(_ enabled: Bool) {
        videoTrack.isEnabled = enabled

        Task { @MainActor in
            if enabled {
                try await startCapture()
            } else {
                try await stopCapture()
            }
        }
    }

    @MainActor
    private func startCapture() async throws {
        guard let device = AVCaptureDevice.videoCaptureDevices(
            withPosition: cameraPosition
        ).first else {
            return
        }

        guard let format = RTCCameraVideoCapturer.supportedFormats(
            for: device
        ).bestFormat(for: qualityProfile) else {
            return
        }

        let fps = format
            .videoSupportedFrameRateRanges
            .bestFrameRate(for: qualityProfile)

        try await capturer.startCapture(
            with: device,
            format: format,
            fps: Int(fps)
        )
    }

    @MainActor
    private func stopCapture() async throws {
        try await Task.sleep(seconds: 0.1)
        await capturer.stopCapture()
        videoTrack.renderEmptyFrame()
    }
}
