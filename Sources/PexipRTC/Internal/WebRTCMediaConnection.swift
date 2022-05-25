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
    private var started = Isolated(false)
    private var shouldRenegotiate = Isolated(false)
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

    func sendMainAudio(localAudioTrack: LocalAudioTrack) {
        guard mainAudioTransceiver == nil else {
            return
        }

        guard let track = localAudioTrack as? WebRTCLocalAudioTrack else {
            preconditionFailure(
                "localAudioTrack must be an instance of WebRtcLocalAudioTrack."
            )
        }

        mainAudioTransceiver = connection.addTransceiver(with: track.rtcTrack)
        mainLocalAudioTrack = track

        track.capturingStatus.$isCapturing.sink { [weak self] isCapturing in
            self?.muteAudio(!isCapturing)
        }.store(in: &cancellables)
    }

    func sendMainVideo(localVideoTrack: CameraVideoTrack) {
        guard mainVideoTransceiver == nil else {
            return
        }

        guard let track = localVideoTrack as? WebRTCCameraVideoTrack else {
            preconditionFailure(
                "localVideoTrack must be an instance of WebRtcLocalVideoTrack."
            )
        }

        mainVideoTransceiver = connection.addTransceiver(with: track.rtcTrack)
        mainLocalVideoTrack = track
        setRemoteVideoTrack(mainVideoTransceiver?.receiver.track as? RTCVideoTrack)

        track.capturingStatus.$isCapturing.sink { [weak self] isCapturing in
            self?.muteVideo(!isCapturing)
        }.store(in: &cancellables)
    }

    #if os(macOS)
    func sendPresentationVideo(screenVideoTrack: ScreenVideoTrack) async throws {
        guard let track = screenVideoTrack as? WebRTCScreenVideoTrack else {
            preconditionFailure(
                "screenVideoTrack must be an instance of WebRTCScreenVideoTrack."
            )
        }

        guard
            let transceiver = presentationVideoTransceiver,
            transceiver.direction != .sendOnly
        else {
            return
        }

        transceiver.sender.track = track.rtcTrack
        try transceiver.setDirection(.sendOnly)
        try await config.signaling.takeFloor()
    }

    func stopSendingPresentation() async throws {
        guard
            let transceiver = presentationVideoTransceiver,
            transceiver.direction == .sendOnly
        else {
            return
        }

        transceiver.sender.track = nil
        try transceiver.setDirection(.inactive)
        try await config.signaling.releaseFloor()
    }

    #endif

    func startPresentationReceive() throws {
        try startReceivingPresentation()
    }

    func startReceivingPresentation() throws {
        guard
            let transceiver = presentationVideoTransceiver,
            transceiver.direction != .recvOnly,
            !config.presentationInMain
        else {
            return
        }

        try transceiver.setDirection(.recvOnly)
        let track = transceiver.receiver.track as? RTCVideoTrack
        setPresentationRemoteVideoTrack(track)
    }

    func stopPresentationReceive() throws {
        try stopReceivingPresentation()
    }

    func stopReceivingPresentation() throws {
        guard
            let transceiver = presentationVideoTransceiver,
            transceiver.direction == .recvOnly,
            !config.presentationInMain
        else {
            return
        }

        try transceiver.setDirection(.inactive)
        setPresentationRemoteVideoTrack(nil)
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
                mainQualityProfile: mainLocalVideoTrack?.qualityProfile,
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
