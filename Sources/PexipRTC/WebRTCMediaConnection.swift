import Combine
import WebRTC
import PexipUtils
import PexipMedia

public final class WebRTCMediaConnection: MediaConnection, ObservableObject {
    @Published public private(set) var isCapturingMainVideo = false
    @Published public private(set) var isAudioMuted = true
    @Published public private(set) var mainLocalVideoTrack: VideoTrack?
    @Published public private(set) var mainRemoteVideoTrack: VideoTrack?
    @Published public private(set) var presentationRemoteVideoTrack: VideoTrack?

    public var statePublisher: AnyPublisher<ConnectionState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    private let config: MediaConnectionConfig
    private let signaling: MediaConnectionSignaling
    private let factory: RTCPeerConnectionFactory
    private let connection: RTCPeerConnection
    private let connectionDelegateProxy: PeerConnectionDelegateProxy
    private let logger: Logger?
    private var started = Isolated(false)
    private var shouldRenegotiate = Isolated(false)
    private var mainAudioTrack: RTCAudioTrack?
    private var mainAudioTransceiver: RTCRtpTransceiver?
    private var mainVideoTransceiver: RTCRtpTransceiver?
    private var mainVideoCapturer: RTCCameraVideoCapturer?
    private var mainVideoCaptureDevice: AVCaptureDevice?
    private var presentationVideoTransceiver: RTCRtpTransceiver?
    private let stateSubject = PassthroughSubject<ConnectionState, Never>()
    private var sendOfferTask: Task<String, Error>?
    #if os(iOS)
    private lazy var audioManager = AudioManager()
    #endif

    // MARK: - Init

    public convenience init(
        config: MediaConnectionConfig,
        signaling: MediaConnectionSignaling,
        logger: Logger? = DefaultLogger.mediaWebRTC
    ) {
        self.init(
            config: config,
            signaling: signaling,
            factory: .default,
            logger: logger
        )
    }

    init(
        config: MediaConnectionConfig,
        signaling: MediaConnectionSignaling,
        factory: RTCPeerConnectionFactory,
        logger: Logger? = nil
    ) {
        connectionDelegateProxy = PeerConnectionDelegateProxy(logger: logger)

        guard let connection = factory.peerConnection(
            with: .defaultConfiguration(withIceServers: config.iceServers),
            constraints: RTCMediaConstraints(
                mandatoryConstraints: nil,
                optionalConstraints: nil
            ),
            delegate: connectionDelegateProxy
        ) else {
            fatalError("Could not create new RTCPeerConnection")
        }

        self.config = config
        self.signaling = signaling
        self.factory = factory
        self.connection = connection
        self.logger = logger
        self.connectionDelegateProxy.delegate = self
    }

    deinit {
        stop()
    }

    // MARK: - MediaConnection

    public func sendMainAudio() {
        guard mainAudioTransceiver == nil else {
            return
        }

        let mainAudioSource = factory.audioSource(with: nil)
        let mainAudioTrack = factory.audioTrack(
            with: mainAudioSource,
            trackId: UUID().uuidString
        )
        mainAudioTransceiver = connection.addTransceiver(with: mainAudioTrack)
    }

    public func sendMainVideo() {
        guard mainVideoTransceiver == nil else {
            return
        }

        let mainVideoSource = factory.videoSource()
        let mainVideoTrack = factory.videoTrack(
            with: mainVideoSource,
            trackId: UUID().uuidString
        )
        mainVideoTrack.isEnabled = false
        mainVideoCapturer = RTCCameraVideoCapturer(delegate: mainVideoSource)
        mainVideoTransceiver = connection.addTransceiver(with: mainVideoTrack)
        setLocalVideoTrack(mainVideoTrack)
        setRemoteVideoTrack(mainVideoTransceiver?.receiver.track as? RTCVideoTrack)
    }

    public func startMainCapture() async throws {
        if let device = AVCaptureDevice.videoCaptureDevice(withPosition: .front) {
            try await startMainCapture(with: device)
        }
    }

    public func startMainCapture(with device: AVCaptureDevice) async throws {
        if isCapturingMainVideo {
            try await stopMainCapture()
        }

        guard let capturer = mainVideoCapturer else {
            return
        }

        guard let format = config.mainQualityProfile.bestFormat(
            from: RTCCameraVideoCapturer.supportedFormats(for: device),
            formatDescription: \.formatDescription
        ) else {
            return
        }

        guard let fps = config.mainQualityProfile.bestFrameRate(
            from: format.videoSupportedFrameRateRanges,
            maxFrameRate: \.maxFrameRate
        ) else {
            return
        }

        updateMainLocalVideoTrack { track in
            track?.isEnabled = true
        }

        try await capturer.startCapture(
            with: device,
            format: format,
            fps: Int(fps)
        )

        mainVideoCaptureDevice = device
        isCapturingMainVideo = true
        try await signaling.muteVideo(false)
    }

    public func stopMainCapture() async throws {
        guard isCapturingMainVideo else {
            return
        }

        guard let mainVideoCapturer = mainVideoCapturer else {
            return
        }

        try await Task.sleep(seconds: 0.1)
        await mainVideoCapturer.stopCapture()
        updateMainLocalVideoTrack { track in
            track?.renderEmptyFrame()
            track?.isEnabled = false
        }
        isCapturingMainVideo = false
        try await signaling.muteVideo(true)
    }

    #if os(iOS)
    public func toggleMainCaptureCamera() async throws {
        guard let currentDevice = mainVideoCaptureDevice, isCapturingMainVideo else {
            return
        }
        if let newDevice = AVCaptureDevice.videoCaptureDevice(
            withPosition: currentDevice.position == .front ? .back : .front
        ) {
            // Restart the video capturing using another camera
            try await stopMainCapture()
            try await startMainCapture(with: newDevice)
        }
    }
    #endif

    public func startPresentationReceive() throws {
        guard
            let transceiver = presentationVideoTransceiver,
            transceiver.direction != .recvOnly
        else {
            return
        }

        var error: NSError?
        transceiver.setDirection(.recvOnly, error: &error)

        if let error = error {
            throw error
        }

        let track = transceiver.receiver.track as? RTCVideoTrack
        setPresentationRemoteVideoTrack(track)
    }

    public func stopPresentationReceive() throws {
        guard
            let transceiver = presentationVideoTransceiver,
            transceiver.direction != .inactive
        else {
            return
        }

        var error: NSError?
        transceiver.setDirection(.inactive, error: &error)

        if let error = error {
            throw error
        }

        setPresentationRemoteVideoTrack(nil)
    }

    public func muteAudio(_ muted: Bool) async throws {
        guard muted != isAudioMuted else {
            return
        }
        mainAudioTrack?.isEnabled = muted
        isAudioMuted = muted
        try await signaling.muteAudio(muted)
    }

    public func start() async throws {
        guard await !started.value else {
            return
        }

        // TODO: Temp workaround for MCU bug #28176
        // Guest gets disconnected after some time without host being present
        if mainAudioTransceiver == nil {
            sendMainAudio()
        }

        if !config.presentationInMain {
            presentationVideoTransceiver = connection.addTransceiver(
                of: .video,
                init: .init(direction: .inactive)
            )
        }

        await started.setValue(true)
        try await createOffer()
    }

    public func stop() {
        mainVideoCapturer?.stopCapture { [weak self] in
            self?.updateMainLocalVideoTrack { track in
                track?.renderEmptyFrame()
            }
        }

        let transceivers = [
            mainAudioTransceiver,
            mainVideoTransceiver,
            presentationVideoTransceiver
        ].compactMap { $0 }

        for transceiver in transceivers {
            transceiver.stopInternal()
            connection.removeTrack(transceiver.sender)
        }

        connection.close()
        mainAudioTransceiver = nil
        mainAudioTrack = nil
        mainVideoTransceiver = nil
        mainVideoCapturer = nil
        mainVideoCaptureDevice = nil
        mainLocalVideoTrack = nil
        mainRemoteVideoTrack = nil
        presentationRemoteVideoTrack = nil
        presentationVideoTransceiver = nil

        Task {
            await started.setValue(false)
        }
    }

    // MARK: - Private

    private func negotiateIfNeeded() {
        Task {
            do {
                if await shouldRenegotiate.value {
                    try await createOffer()
                } else {
                    await shouldRenegotiate.setValue(true)
                }
            } catch {
                logger?.debug("Cannot create offer: \(error)")
            }
        }
    }

    private func createOffer() async throws {
        sendOfferTask = Task {
            let constraints = RTCMediaConstraints(
                mandatoryConstraints: nil,
                optionalConstraints: [
                    "DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue
                ]
            )
            let offer = try await connection.offer(for: constraints)
            try await connection.setLocalDescription(offer)

            let mangler = SessionDescriptionMangler(sdp: offer.sdp)
            let newLocalSdp = mangler.mangle(
                mainQualityProfile: config.mainQualityProfile,
                mainAudioMid: mainAudioTransceiver?.mid,
                mainVideoMid: mainVideoTransceiver?.mid,
                presentationVideoMid: presentationVideoTransceiver?.mid
            )

            return try await signaling.sendOffer(
                callType: "WEBRTC",
                description: newLocalSdp,
                presentationInMain: config.presentationInMain
            )
        }

        let remoteSdp = try await sendOfferTask!.value
        let answer = RTCSessionDescription(type: .answer, sdp: remoteSdp)
        try await connection.setRemoteDescription(answer)
    }

    private func setLocalVideoTrack(_ track: RTCVideoTrack?) {
        #if !targetEnvironment(simulator)
        Task { @MainActor in
            if let track = track {
                mainLocalVideoTrack = DefaultVideoTrack(
                    rtcTrack: track,
                    aspectRatio: config.mainQualityProfile.aspectRatio
                )
            } else {
                mainLocalVideoTrack = nil
            }
        }
        #endif
    }

    private func updateMainLocalVideoTrack(_ update: (DefaultVideoTrack?) -> Void) {
        update(mainLocalVideoTrack as? DefaultVideoTrack)
    }

    private func setRemoteVideoTrack(_ track: RTCVideoTrack?) {
        Task { @MainActor in
            mainRemoteVideoTrack = track.map {
                DefaultVideoTrack(
                    rtcTrack: $0,
                    aspectRatio: CGSize(width: 16, height: 9)
                )
            }
        }
    }

    private func setPresentationRemoteVideoTrack(_ track: RTCVideoTrack?) {
        Task { @MainActor in
            presentationRemoteVideoTrack = track.map {
                DefaultVideoTrack(
                    rtcTrack: $0,
                    aspectRatio: CGSize(width: 16, height: 9)
                )
            }
        }
    }
}

// MARK: - PeerConnectionDelegate

extension WebRTCMediaConnection: PeerConnectionDelegate {
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        if ![.closed, .disconnected].contains(peerConnection.connectionState) {
            negotiateIfNeeded()
        }
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChange newState: ConnectionState
    ) {
        Task { @MainActor in
            stateSubject.send(newState)
        }

        if newState == .connected {
            #if os(iOS)
            audioManager.speakerOn()
            #endif
        }
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didGenerate candidate: RTCIceCandidate
    ) {
        guard let sendOfferTask = sendOfferTask else {
            return
        }

        Task {
            do {
                _ = try await sendOfferTask.value
                try await signaling.addCandidate(
                    sdp: candidate.sdp,
                    mid: candidate.sdpMid
                )
            } catch {
                logger?.error(
                    "MediaConnectionSignaling.onCandidate failed with error: \(error)"
                )
            }
        }
    }
}
