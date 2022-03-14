import WebRTC

final class WebRTCLocalVideoTrack: LocalVideoTrackProtocol {
    var aspectRatio: CGSize { qualityProfile.aspectRatio }

    private(set) var capturePermission: MediaCapturePermission
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
        capturePermission: MediaCapturePermission,
        qualityProfile: QualityProfile,
        streamId: String
    ) {
        let videoSource = factory.videoSource()
        let track = factory.videoTrack(with: videoSource, trackId: UUID().uuidString)
        track.isEnabled = false

        self.videoTrack = WebRTCVideoTrack(
            track: track,
            aspectRatio: qualityProfile.aspectRatio
        )
        self.capturer = RTCCameraVideoCapturer(delegate: videoSource)
        self.trackSender = trackManager.add(track, streamIds: [streamId])
        self.trackManager = trackManager
        self.qualityProfile = qualityProfile
        self.capturePermission = capturePermission
    }

    deinit {
        if let trackSender = trackSender {
            _ = trackManager?.removeTrack(trackSender)
        }

        if videoTrack.isEnabled {
            videoTrack.setEnabled(false)
            capturer.stopCapture { [weak videoTrack] in
                videoTrack?.renderEmptyFrame()
            }
        }
    }

    // MARK: - Internal

    var isEnabled: Bool {
        videoTrack.isEnabled && capturePermission.isAuthorized
    }

    @MainActor
    @discardableResult
    func setEnabled(_ enabled: Bool) async -> Bool {
        guard isEnabled != enabled else {
            return isEnabled
        }

        videoTrack.setEnabled(enabled)

        if enabled {
            await capturePermission.requestAccess(openSettingsIfNeeded: true)
        }

        guard isEnabled else {
            return false
        }

        _ = await Task { @MainActor in
            if enabled {
                try await startCapture()
            } else {
                try await stopCapture()
            }
        }.result

        return videoTrack.isEnabled
    }

    func setRenderer(_ view: VideoView, aspectFit: Bool) {
        videoTrack.setRenderer(view, aspectFit: aspectFit)
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
