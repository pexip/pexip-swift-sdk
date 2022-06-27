import Combine
import WebRTC
import PexipUtils
import PexipMedia

final class WebRTCMediaConnection: MediaConnection {
    var remoteVideoTracks = RemoteVideoTracks(
        mainTrack: nil,
        presentationTrack: nil
    )

    var statePublisher: AnyPublisher<MediaConnectionState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    private let config: MediaConnectionConfig
    private let factory: RTCPeerConnectionFactory
    private let connection: RTCPeerConnection
    private let connectionDelegateProxy: PeerConnectionDelegateProxy
    private let logger: Logger?
    private let started = Isolated(false)
    private let shouldRenegotiate = Isolated(false)
    private var mainAudioTransceiver: RTCRtpTransceiver?
    private var mainVideoTransceiver: RTCRtpTransceiver?
    private var presentationVideoTransceiver: RTCRtpTransceiver?
    private var mainLocalAudioTrack: WebRTCLocalAudioTrack?
    private var mainLocalVideoTrack: WebRTCCameraVideoTrack?
    private let stateSubject = PassthroughSubject<MediaConnectionState, Never>()
    private var sendOfferTask: Task<String, Error>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        config: MediaConnectionConfig,
        factory: RTCPeerConnectionFactory,
        logger: Logger? = nil
    ) {
        connectionDelegateProxy = PeerConnectionDelegateProxy(logger: logger)

        guard let connection = factory.peerConnection(
            with: .defaultConfiguration(
                withIceServers: config.iceServers,
                dscp: config.dscp
            ),
            constraints: RTCMediaConstraints(
                mandatoryConstraints: nil,
                optionalConstraints: nil
            ),
            delegate: connectionDelegateProxy
        ) else {
            fatalError("Could not create new RTCPeerConnection")
        }

        self.config = config
        self.factory = factory
        self.connection = connection
        self.logger = logger
        self.connectionDelegateProxy.delegate = self
        createPresentationVideoTransceiverIfNeeded()
    }

    deinit {
        stop()
    }

    // MARK: - MediaConnection

    func start() async throws {
        guard await !started.value else {
            return
        }

        await started.setValue(true)
        createPresentationVideoTransceiverIfNeeded()
        try await createOffer()
    }

    func stop() {
        connection.close()
        sendOfferTask?.cancel()
        sendOfferTask = nil
        cancellables.removeAll()

        mainLocalVideoTrack = nil
        mainLocalAudioTrack = nil

        let transceivers = [
            mainAudioTransceiver,
            mainVideoTransceiver,
            presentationVideoTransceiver
        ].compactMap { $0 }

        for transceiver in transceivers {
            transceiver.stopInternal()
            connection.removeTrack(transceiver.sender)
        }

        mainAudioTransceiver = nil
        mainVideoTransceiver = nil
        presentationVideoTransceiver = nil

        remoteVideoTracks.mainTrack = nil
        remoteVideoTracks.presentationTrack = nil

        Task {
            await started.setValue(false)
        }
    }

    func setMainAudioTrack(_ audioTrack: LocalAudioTrack?) {
        mainLocalAudioTrack = audioTrack.valueOrNil(WebRTCLocalAudioTrack.self)
        mainAudioTransceiver = mainAudioTransceiver ?? connection.addTransceiver(of: .audio)
        mainAudioTransceiver?.sender.track = mainLocalAudioTrack?.rtcTrack
        mainLocalAudioTrack?.capturingStatus.$isCapturing.sink { [weak self] isCapturing in
            self?.muteAudio(!isCapturing)
        }.store(in: &cancellables)
    }

    func setMainVideoTrack(_ videoTrack: CameraVideoTrack?) {
        mainLocalVideoTrack = videoTrack.valueOrNil(WebRTCCameraVideoTrack.self)

        let shouldSetRemoteVideoTrack = mainVideoTransceiver == nil
        mainVideoTransceiver = mainVideoTransceiver ?? connection.addTransceiver(of: .video)
        mainVideoTransceiver?.sender.track = mainLocalVideoTrack?.rtcTrack

        if shouldSetRemoteVideoTrack {
            setRemoteVideoTrack(mainVideoTransceiver?.receiver.track as? RTCVideoTrack)
        }

        mainLocalVideoTrack?.capturingStatus.$isCapturing.sink { [weak self] isCapturing in
            self?.muteVideo(!isCapturing)
        }.store(in: &cancellables)
    }

    func setScreenMediaTrack(_ screenMediaTrack: ScreenMediaTrack?) {
        let track = screenMediaTrack.valueOrNil(WebRTCScreenMediaTrack.self)
        presentationVideoTransceiver?.sender.track = track?.rtcTrack
        track?.capturingStatus.$isCapturing.sink { [weak self] isCapturing in
            self?.toggleLocalPresentation(isCapturing)
        }.store(in: &cancellables)
    }

    func receivePresentation(_ receive: Bool) throws {
        guard
            let transceiver = presentationVideoTransceiver,
            !config.presentationInMain
        else {
            return
        }

        switch receive {
        case true where transceiver.direction != .recvOnly:
            try transceiver.setDirection(.recvOnly)
            let track = transceiver.receiver.track as? RTCVideoTrack
            setPresentationRemoteVideoTrack(track)
        case false where transceiver.direction == .recvOnly:
            try transceiver.setDirection(.inactive)
            setPresentationRemoteVideoTrack(nil)
        default:
            break
        }
    }

    // MARK: - Private

    private func negotiateIfNeeded() {
        Task {
            do {
                // Skip the first call to negotiateIfNeeded() since it's
                // called right after RTCPeerConnection creation,
                // and we're still not ready to use createOffer()
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
                bandwidth: config.bandwidth,
                mainQualityProfile: mainLocalVideoTrack?.videoProfile,
                mainAudioMid: mainAudioTransceiver?.mid,
                mainVideoMid: mainVideoTransceiver?.mid,
                presentationVideoMid: presentationVideoTransceiver?.mid
            )

            return try await config.signaling.sendOffer(
                callType: "WEBRTC",
                description: newLocalSdp,
                presentationInMain: config.presentationInMain
            )
        }

        let remoteSdp = try await sendOfferTask!.value
        let answer = RTCSessionDescription(type: .answer, sdp: remoteSdp)
        try await connection.setRemoteDescription(answer)
    }

    private func muteVideo(_ muted: Bool) {
        Task {
            try await config.signaling.muteVideo(muted)
        }
    }

    private func muteAudio(_ muted: Bool) {
        Task {
            try await config.signaling.muteAudio(muted)
        }
    }

    private func toggleLocalPresentation(_ isPresenting: Bool) {
        guard let transceiver = presentationVideoTransceiver else {
            return
        }

        Task {
            do {
                switch isPresenting {
                case true where transceiver.direction != .sendRecv:
                    setPresentationRemoteVideoTrack(nil)
                    try transceiver.setDirection(.sendRecv)
                    try await config.signaling.takeFloor()
                case false where transceiver.direction == .sendRecv:
                    try transceiver.setDirection(.inactive)
                    try await config.signaling.releaseFloor()
                default:
                    break
                }
            } catch {
                logger?.error("Error on taking/releasing presentation floor: \(error)")
            }
        }
    }

    private func setRemoteVideoTrack(_ track: RTCVideoTrack?) {
        Task { @MainActor in
            remoteVideoTracks.mainTrack = track.map {
                WebRTCVideoTrack(rtcTrack: $0)
            }
        }
    }

    private func setPresentationRemoteVideoTrack(_ track: RTCVideoTrack?) {
        Task { @MainActor in
            remoteVideoTracks.presentationTrack = track.map {
                WebRTCVideoTrack(rtcTrack: $0)
            }
        }
    }

    private func createPresentationVideoTransceiverIfNeeded() {
        if presentationVideoTransceiver == nil {
            presentationVideoTransceiver = connection.addTransceiver(
                of: .video,
                init: .init(direction: .inactive)
            )
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
        didChange newState: MediaConnectionState
    ) {
        Task { @MainActor in
            stateSubject.send(newState)
        }

        if newState == .connected {
            #if os(iOS)
            mainLocalAudioTrack?.speakerOn()
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
                try await config.signaling.addCandidate(
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

// MARK: - Private extension

extension Optional {
    func valueOrNil<T>(_ type: T.Type) -> T? {
        switch self {
        case .none:
            return nil
        case .some(let value):
            if let value = value as? T {
                return value
            } else {
                preconditionFailure(
                    "Value must be an instance of \(T.self)."
                )
            }
        }
    }
}
