import WebRTC

final class RTCCameraComponent {
    private weak var trackManager: RTCTrackManager?
    private let capturer: RTCCameraVideoCapturer
    private var trackSender: RTCRtpSender?
    @MainActor private let videoComponent: RTCVideoComponent
    @MainActor private var isMuted = false
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

        self.videoComponent = RTCVideoComponent(track: track)
        self.capturer = RTCCameraVideoCapturer(delegate: videoSource)
        self.trackSender = trackManager.add(track, streamIds: [streamId])
        self.trackManager = trackManager
    }

    deinit {
        if let trackSender = trackSender {
            _ = trackManager?.removeTrack(trackSender)
        }

        if videoComponent.isEnabled {
            videoComponent.isEnabled = false
            capturer.stopCapture { [weak videoComponent] in
                videoComponent?.renderEmptyFrame()
            }
        }
    }

    // MARK: - Internal methods

    func render(to renderer: RTCVideoRenderer) {
        videoComponent.render(to: renderer)
    }

    @MainActor
    func startCapture() async throws {
        guard !videoComponent.isEnabled, !isMuted else {
            return
        }

        guard let config = config else {
            return
        }

        try await capturer.startCapture(
            with: config.device,
            format: config.format,
            fps: Int(config.fps.maxFrameRate)
        )

        videoComponent.isEnabled = true
    }

    @MainActor
    func stopCaptureGracefully() async throws {
        guard videoComponent.isEnabled else {
            return
        }

        videoComponent.isEnabled = false

        try await Task.sleep(seconds: 0.1)
        await capturer.stopCapture()
        videoComponent.renderEmptyFrame()
    }

    @MainActor
    func setCameraMuted(_ isMuted: Bool) async throws {
        guard self.isMuted != isMuted else {
            return
        }

        if isMuted {
            try await stopCaptureGracefully()
        } else {
            try await startCapture()
        }

        self.isMuted = isMuted
    }

    @MainActor
    func toggleCamera() async throws {
        cameraPosition = cameraPosition == .front ? .back : .front

        // Restart the video capturing using another camera
        try await stopCaptureGracefully()
        isMuted = true
        try await setCameraMuted(false)
    }

    // MARK: - Private methods

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
