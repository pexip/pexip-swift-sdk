import WebRTC

final class WebRTCLocalVideoTrack: LocalVideoTrackProtocol {
    var isEnabled: Bool {
        get { videoTrack.isEnabled }
        set {
            guard videoTrack.isEnabled != newValue else {
                return
            }
            setEnabled(newValue)
        }
    }

    private weak var trackManager: RTCTrackManager?
    private let capturer: RTCCameraVideoCapturer
    private var trackSender: RTCRtpSender?
    @MainActor private let videoTrack: WebRTCVideoTrack
    @MainActor private var cameraPosition: AVCaptureDevice.Position = .front

    // MARK: - Init

    init(
        factory: RTCPeerConnectionFactory,
        trackManager: RTCTrackManager,
        streamId: String
    ) {
        let videoSource = factory.videoSource()
        let track = factory.videoTrack(with: videoSource, trackId: UUID().uuidString)
        track.isEnabled = false

        self.videoTrack = WebRTCVideoTrack(track: track)
        self.capturer = RTCCameraVideoCapturer(delegate: videoSource)
        self.trackSender = trackManager.add(track, streamIds: [streamId])
        self.trackManager = trackManager
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
        guard let config = config else {
            return
        }

        try await capturer.startCapture(
            with: config.device,
            format: config.format,
            fps: Int(config.fps.maxFrameRate)
        )
    }

    @MainActor
    private func stopCapture() async throws {
        try await Task.sleep(seconds: 0.1)
        await capturer.stopCapture()
        videoTrack.renderEmptyFrame()
    }

    @MainActor
    private var config: CaptureConfig? {
        let captureDevices = RTCCameraVideoCapturer.captureDevices()

        guard let device = captureDevices.first(where: {
            $0.position == cameraPosition
        }) else {
            return nil
        }

        let supportedFormats = RTCCameraVideoCapturer.supportedFormats(for: device)

        guard let format = supportedFormats.sorted(by: {
            let width1 = CMVideoFormatDescriptionGetDimensions($0.formatDescription).width
            let width2 = CMVideoFormatDescriptionGetDimensions($1.formatDescription).width
            return width1 < width2
        }).last else {
            return nil
        }

        guard let fps = (format.videoSupportedFrameRateRanges.sorted {
            $0.maxFrameRate < $1.maxFrameRate
        }).last else {
            return nil
        }

        return CaptureConfig(device: device, format: format, fps: fps)
    }
}

// MARK: - Private types

private struct CaptureConfig {
    let device: AVCaptureDevice
    let format: AVCaptureDevice.Format
    let fps: AVFrameRateRange
}
