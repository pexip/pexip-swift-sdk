import Combine
import WebRTC
import PexipUtils
import PexipMedia

public final class WebRTCMediaConnection: MediaConnection, ObservableObject {
    @Published public private(set) var isCapturingMainVideo = false
    @Published public private(set) var isAudioMuted = true
    @Published public private(set) var mainLocalVideoTrack: VideoTrack?
    @Published public private(set) var mainRemoteVideoTrack: VideoTrack?
    @available(*, unavailable)
    @Published public private(set) var presentationRemoteVideoTrack: VideoTrack?

    public var statePublisher: AnyPublisher<ConnectionState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    private let signaling: MediaConnectionSignaling
    private let factory: RTCPeerConnectionFactory
    private let connection: RTCPeerConnection
    private let connectionDelegateProxy: PeerConnectionDelegateProxy
    private let logger: Logger?
    private let mainQualityProfile: QualityProfile
    private let presentationType: PresentationType?
    private var started = Isolated(false)
    private var shouldRenegotiate = Isolated(false)
    private var mainAudioTrack: RTCAudioTrack?
    private var mainAudioTransceiver: RTCRtpTransceiver?
    private var mainVideoTransceiver: RTCRtpTransceiver?
    private var mainVideoCapturer: RTCCameraVideoCapturer?
    private var mainVideoCaptureDevice: AVCaptureDevice?
    private lazy var presentationVideoTransceiver: RTCRtpTransceiver? = connection
        .addTransceiver(of: .video, init: .init(direction: .sendOnly))
    private let stateSubject = PassthroughSubject<ConnectionState, Never>()
    #if os(iOS)
    private lazy var audioManager = AudioManager()
    #endif

    // MARK: - Init

    public convenience init(
        signaling: MediaConnectionSignaling,
        iceServers: [String] = [],
        useGoogleStunServersAsBackup: Bool = true,
        mainQualityProfile: QualityProfile = .medium,
        presentationType: PresentationType? = nil,
        logger: Logger? = DefaultLogger.mediaWebRTC
    ) {
        self.init(
            factory: .default,
            signaling: signaling,
            iceServers: iceServers,
            useGoogleStunServersAsBackup: useGoogleStunServersAsBackup,
            mainQualityProfile: mainQualityProfile,
            presentationType: presentationType,
            logger: logger
        )
    }

    init(
        factory: RTCPeerConnectionFactory,
        signaling: MediaConnectionSignaling,
        iceServers: [String],
        useGoogleStunServersAsBackup: Bool = true,
        mainQualityProfile: QualityProfile = .medium,
        presentationType: PresentationType? = nil,
        logger: Logger? = nil
    ) {
        connectionDelegateProxy = PeerConnectionDelegateProxy(logger: logger)

        guard let connection = factory.peerConnection(
            with: .defaultConfiguration(
                withIceServers: iceServers,
                useGoogleStunServersAsBackup: useGoogleStunServersAsBackup
            ),
            constraints: RTCMediaConstraints(
                mandatoryConstraints: nil,
                optionalConstraints: nil
            ),
            delegate: connectionDelegateProxy
        ) else {
            fatalError("Could not create new RTCPeerConnection")
        }

        self.signaling = signaling
        self.factory = factory
        self.connection = connection
        self.mainQualityProfile = mainQualityProfile
        self.presentationType = presentationType
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

        guard let format = mainQualityProfile.bestFormat(
            from: RTCCameraVideoCapturer.supportedFormats(for: device),
            formatDescription: \.formatDescription
        ) else {
            return
        }

        guard let fps = mainQualityProfile.bestFrameRate(
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

    public func muteAudio(_ muted: Bool) {
        guard muted != isAudioMuted else {
            return
        }
        mainAudioTrack?.isEnabled = muted
        isAudioMuted = muted
    }

    public func start() async throws {
        guard await !started.value else {
            return
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

        if let mainVideoTransceiver = mainVideoTransceiver {
            mainVideoTransceiver.stopInternal()
            connection.removeTrack(mainVideoTransceiver.sender)
        }

        connection.close()
        mainAudioTransceiver = nil
        mainAudioTrack = nil
        mainVideoTransceiver = nil
        mainVideoCapturer = nil
        mainVideoCaptureDevice = nil
        mainLocalVideoTrack = nil
        mainRemoteVideoTrack = nil
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
            mainQualityProfile: mainQualityProfile,
            mainAudioMid: mainAudioTransceiver?.mid,
            mainVideoMid: mainVideoTransceiver?.mid,
            presentationVideoMid: presentationVideoTransceiver?.mid
        )

        let remoteSdp = try await signaling.onOffer(
            callType: "WEBRTC",
            description: newLocalSdp,
            presentationType: presentationType
        )
        let answer = RTCSessionDescription(type: .answer, sdp: remoteSdp)
        try await connection.setRemoteDescription(answer)
    }

    private func setLocalVideoTrack(_ track: RTCVideoTrack?) {
        #if !targetEnvironment(simulator)
        Task { @MainActor in
            if let track = track {
                mainLocalVideoTrack = DefaultVideoTrack(
                    rtcTrack: track,
                    aspectRatio: mainQualityProfile.aspectRatio
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
            if let track = track {
                mainRemoteVideoTrack = DefaultVideoTrack(
                    rtcTrack: track,
                    aspectRatio: CGSize(width: 16, height: 9)
                )
            } else {
                mainRemoteVideoTrack = nil
            }
        }
    }
}

// MARK: - PeerConnectionDelegate

extension WebRTCMediaConnection: PeerConnectionDelegate {
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        negotiateIfNeeded()
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChange newState: ConnectionState
    ) {
        Task { @MainActor in
            stateSubject.send(newState)
        }

        guard newState == .connected else {
            return
        }

        #if os(iOS)
        audioManager.speakerOn()
        #endif

        Task {
            do {
                try await signaling.onConnected()
            } catch {
                logger?.error(
                    "MediaConnectionSignaling.onConnected failed with error: \(error)"
                )
            }
        }
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didGenerate candidate: RTCIceCandidate
    ) {
        Task {
            do {
                try await signaling.onCandidate(
                    candidate: candidate.sdp,
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
