//
// Copyright 2022-2023 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Combine
import WebRTC
import PexipCore
import PexipMedia

// swiftlint:disable file_length
final class WebRTCMediaConnection: NSObject, MediaConnection {
    var remoteVideoTracks = RemoteVideoTracks(
        mainTrack: nil,
        presentationTrack: nil
    )

    var statePublisher: AnyPublisher<MediaConnectionState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var secureCheckCode: SecureCheckCode {
        fingerprintStore.secureCheckCode
    }

    private let config: MediaConnectionConfig
    private let factory: RTCPeerConnectionFactory
    private let connection: RTCPeerConnection
    private let connectionDelegateProxy: PeerConnectionDelegateProxy
    private let logger: Logger?

    private var mainAudioTransceiver: RTCRtpTransceiver?
    private var mainVideoTransceiver: RTCRtpTransceiver?
    private var presentationVideoTransceiver: RTCRtpTransceiver?

    private var mainLocalAudioTrack: WebRTCLocalAudioTrack?
    private var mainLocalVideoTrack: WebRTCCameraVideoTrack?

    private let started = Synchronized(false)
    private let isMakingOffer = Synchronized(false)
    private let isReceivingOffer = Synchronized(false)
    private let shouldRenegotiate = Synchronized(false)
    private let isPolitePeer = Synchronized(false)
    private let shouldAck = Synchronized(true)
    private var canReceiveOffer: Bool {
        isPolitePeer.value || !hasOfferCollision
    }
    private var hasOfferCollision: Bool {
        isMakingOffer.value || connection.signalingState != .stable
    }

    private var signalingChannel: SignalingChannel { config.signaling }
    private var localDataChannel: RTCDataChannel?
    private var incomingIceCandidates = Synchronized([RTCIceCandidate]())
    private var outgoingIceCandidates = Synchronized([RTCIceCandidate]())
    private let fingerprintStore = FingerprintStore()
    private let stateSubject = PassthroughSubject<MediaConnectionState, Never>()
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
        super.init()

        self.connectionDelegateProxy.delegate = self
        subscribeToEvents()
    }

    deinit {
        stop()
    }

    // MARK: - MediaConnection (tracks)

    func setMainAudioTrack(_ audioTrack: LocalAudioTrack?) throws {
        mainLocalAudioTrack = audioTrack.valueOrNil(WebRTCLocalAudioTrack.self)

        if mainAudioTransceiver == nil && mainLocalAudioTrack != nil {
            mainAudioTransceiver = connection.addAudioTransceiver(.sendOnly)
        }

        try mainAudioTransceiver?.send(from: mainLocalAudioTrack?.rtcTrack)

        let status = mainLocalAudioTrack?.capturingStatus ?? CapturingStatus(isCapturing: false)
        status.$isCapturing.sink { [weak self] isCapturing in
            self?.muteAudio(!isCapturing)
        }.store(in: &cancellables)
    }

    func setMainVideoTrack(_ videoTrack: CameraVideoTrack?) throws {
        mainLocalVideoTrack = videoTrack.valueOrNil(WebRTCCameraVideoTrack.self)

        if mainVideoTransceiver == nil && mainLocalVideoTrack != nil {
            mainVideoTransceiver = connection.addVideoTransceiver(.sendOnly)
        }

        try mainVideoTransceiver?.send(from: mainLocalVideoTrack?.rtcTrack)

        let status = mainLocalVideoTrack?.capturingStatus ?? CapturingStatus(isCapturing: false)
        status.$isCapturing.sink { [weak self] isCapturing in
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

    // MARK: - MediaConnection (lifecycle)

    func start() async throws {
        guard !started.value else {
            return
        }

        started.setValue(true)
        createPresentationVideoTransceiverIfNeeded()
        createDataChannelIfNeeded()
        try await sendOffer()
    }

    func stop() {
        connection.close()
        cancellables.removeAll()

        mainLocalVideoTrack = nil
        mainLocalAudioTrack = nil

        let transceivers = [
            mainAudioTransceiver,
            mainVideoTransceiver,
            presentationVideoTransceiver
        ].compactMap { $0 }

        transceivers.forEach(connection.stopTransceiver(_:))

        mainAudioTransceiver = nil
        mainVideoTransceiver = nil
        presentationVideoTransceiver = nil

        remoteVideoTracks.setMainTrack(nil)
        remoteVideoTracks.setPresentationTrack(nil)

        started.setValue(false)
        isMakingOffer.setValue(false)
        isReceivingOffer.setValue(false)
        shouldRenegotiate.setValue(false)
        isPolitePeer.setValue(false)
        shouldAck.setValue(true)

        signalingChannel.data?.sender = nil
        localDataChannel?.close()
        localDataChannel = nil

        incomingIceCandidates.setValue([])
        outgoingIceCandidates.setValue([])
    }

    func receiveRemoteAudio(_ receive: Bool) throws {
        if let mainAudioTransceiver {
            try mainAudioTransceiver.receive(receive)
        } else if receive {
            mainAudioTransceiver = connection.addAudioTransceiver(.recvOnly)
        }
    }

    func receiveRemoteVideo(_ receive: Bool) throws {
        if let mainVideoTransceiver {
            try mainVideoTransceiver.receive(receive)
        } else if receive {
            mainVideoTransceiver = connection.addVideoTransceiver(.recvOnly)
        }
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
            if let track = transceiver.receiver.track as? RTCVideoTrack {
                remoteVideoTracks.setPresentationTrack(
                    WebRTCVideoTrack(rtcTrack: track)
                )
            }
        case false where transceiver.direction == .recvOnly:
            try transceiver.setDirection(.inactive)
            remoteVideoTracks.setPresentationTrack(nil)
        default:
            break
        }
    }

    // MARK: - Other

    @discardableResult
    func dtmf(signals: DTMFSignals) async throws -> Bool {
        try await signalingChannel.dtmf(signals: signals)
    }
}

// MARK: - Private

private extension WebRTCMediaConnection {
    func sendOffer() async throws {
        isMakingOffer.setValue(true)
        defer {
            isMakingOffer.setValue(false)
        }

        logger?.debug("Outgoing offer - initiated")
        try await connection.setLocalDescription()

        do {
            guard let localDescription = connection.localDescription,
                  !isReceivingOffer.value
            else {
                return
            }

            fingerprintStore.setLocalFingerprints(fingerprints(from: localDescription))

            if let remoteDescription = try await config.signaling.sendOffer(
                callType: "WEBRTC",
                description: mangle(description: localDescription),
                presentationInMain: config.presentationInMain
            ).map({
                RTCSessionDescription(type: .answer, sdp: $0)
            }) {
                try await addOutgoingIceCandidatesIfNeeded()
                if !isReceivingOffer.value && connection.signalingState == .haveLocalOffer {
                    try await connection.setRemoteDescription(remoteDescription)
                    fingerprintStore.setRemoteFingerprints(fingerprints(from: remoteDescription))
                }
            } else {
                try await addOutgoingIceCandidatesIfNeeded()
                isPolitePeer.setValue(true)
            }

            if shouldAck.value {
                shouldAck.setValue(false)
                try await config.signaling.ack()
            }
            logger?.debug("Outgoing offer - received answer, isPolitePeer=\(isPolitePeer.value)")
        } catch {
            logger?.error("Outgoing offer - failed to send new offer: \(error)")
            outgoingIceCandidates.setValue([])
            throw error
        }
    }

    func receiveNewOffer(_ offer: String) async throws {
        isReceivingOffer.setValue(true)
        defer {
            isReceivingOffer.setValue(false)
        }

        logger?.debug("Incoming offer - received")
        guard canReceiveOffer else {
            logger?.debug("Incoming offer - ignored")
            return
        }

        do {
            let remoteDescription = RTCSessionDescription(type: .offer, sdp: offer)
            try await connection.setRemoteDescription(remoteDescription)
            fingerprintStore.setRemoteFingerprints(fingerprints(from: remoteDescription))

            try await connection.setLocalDescription()
            if let localDescription = connection.localDescription {
                fingerprintStore.setLocalFingerprints(fingerprints(from: localDescription))
                try await config.signaling.sendAnswer(mangle(description: localDescription))
            }

            isReceivingOffer.setValue(false)
            try await addIncomingIceCandidatesIfNeeded()
            logger?.debug("Incoming offer - sent answer")
        } catch {
            incomingIceCandidates.setValue([])
            logger?.error("Incoming offer - failed to accept: \(error)")
            throw error
        }
    }

    func receiveCandidate(_ candidate: String, mid: String?) async throws {
        guard !candidate.isEmpty else {
            return
        }
        let candidate = RTCIceCandidate(
            sdp: candidate,
            sdpMLineIndex: mid.flatMap({ Int32($0) }) ?? 0,
            sdpMid: mid
        )

        do {
            if isReceivingOffer.value {
                incomingIceCandidates.mutate {
                    $0.append(candidate)
                }
            } else {
                try await connection.add(candidate)
                logger?.debug("New incoming ICE candidate added")
            }
        } catch {
            if canReceiveOffer {
                logger?.error("Failed to add new incoming ICE candidate")
                throw error
            }
        }
    }

    func toggleLocalPresentation(_ isPresenting: Bool) {
        guard let transceiver = presentationVideoTransceiver else {
            return
        }

        Task {
            do {
                switch isPresenting {
                case true where transceiver.direction != .sendRecv:
                    remoteVideoTracks.setPresentationTrack(nil)
                    try transceiver.setDirection(.sendRecv)
                    try await signalingChannel.takeFloor()
                case false where transceiver.direction == .sendRecv:
                    try transceiver.setDirection(.inactive)
                    try await signalingChannel.releaseFloor()
                default:
                    break
                }
            } catch {
                logger?.error("Error on taking/releasing presentation floor: \(error)")
            }
        }
    }

    func createPresentationVideoTransceiverIfNeeded() {
        if presentationVideoTransceiver == nil {
            presentationVideoTransceiver = connection.addTransceiver(
                of: .video,
                init: .init(direction: .inactive)
            )
        }
    }

    func createDataChannelIfNeeded() {
        if let dataChannelId = signalingChannel.data?.id, localDataChannel == nil {
            let config = RTCDataChannelConfiguration()
            config.isNegotiated = true
            config.channelId = dataChannelId
            localDataChannel = connection.dataChannel(
                forLabel: "pexChannel",
                configuration: config
            )
            localDataChannel?.delegate = self
            signalingChannel.data?.sender = self
            logger?.debug("Data channel - new data channel created.")
        }
    }

    func addIncomingIceCandidatesIfNeeded() async throws {
        let incomingIceCandidates = self.incomingIceCandidates.value
        self.incomingIceCandidates.setValue([])

        for candidate in incomingIceCandidates {
            try await connection.add(candidate)
            logger?.debug("New incoming ICE candidate added")
        }
    }

    func addOutgoingIceCandidatesIfNeeded() async throws {
        let outgoingIceCandidates = self.outgoingIceCandidates.value
        self.outgoingIceCandidates.setValue([])

        try await withThrowingTaskGroup(of: Void.self) { group in
            for candidate in outgoingIceCandidates {
                group.addTask { [weak self] in
                    try await self?.addOutgoingIceCandidate(candidate)
                }
            }

            try await group.waitForAll()
        }
    }

    func addOutgoingIceCandidate(_ candidate: RTCIceCandidate) async throws {
        try await signalingChannel.addCandidate(
            candidate.sdp,
            mid: candidate.sdpMid
        )
        logger?.debug("New outgoing ICE candidate added")
    }

    func muteVideo(_ muted: Bool) {
        Task {
            try await signalingChannel.muteVideo(muted)
        }
    }

    func muteAudio(_ muted: Bool) {
        Task {
            do {
                try await signalingChannel.muteAudio(muted)
            } catch {
                logger?.error("Cannot mute audio, error: \(error)")
            }
        }
    }

    func mangle(description: RTCSessionDescription) -> String {
        return SessionDescriptionManager(sdp: description.sdp).mangle(
            bandwidth: config.bandwidth,
            mainQualityProfile: mainLocalVideoTrack?.videoProfile,
            mainAudioMid: connection.mid(for: mainAudioTransceiver),
            mainVideoMid: connection.mid(for: mainVideoTransceiver),
            presentationVideoMid: connection.mid(for: presentationVideoTransceiver)
        )
    }

    func fingerprints(from description: RTCSessionDescription) -> [Fingerprint] {
        SessionDescriptionManager(sdp: description.sdp).extractFingerprints()
    }

    func subscribeToEvents() {
        secureCheckCode.$value.sink { [weak self] value in
            self?.logger?.debug("Secure Check Code: \(value)")
        }.store(in: &cancellables)

        config.signaling.eventPublisher.sink { event in
            Task { [weak self] in
                switch event {
                case .newOffer(let sdp):
                    try await self?.receiveNewOffer(sdp)
                case let .newCandidate(candidate, mid):
                    try await self?.receiveCandidate(candidate, mid: mid)
                }
            }
        }.store(in: &cancellables)
    }
}

// MARK: - PeerConnectionDelegate

extension WebRTCMediaConnection: PeerConnectionDelegate {
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        guard ![.closed, .disconnected].contains(peerConnection.connectionState) else {
            return
        }

        // Skip the first call to negotiateIfNeeded() since it's
        // called right after RTCPeerConnection creation,
        // and we're still not ready to use sendOffer()
        if shouldRenegotiate.value {
            Task {
                try await sendOffer()
            }
        } else {
            shouldRenegotiate.setValue(true)
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
        guard !isMakingOffer.value else {
            outgoingIceCandidates.mutate {
                $0.append(candidate)
            }
            return
        }

        Task {
            do {
                try await addOutgoingIceCandidate(candidate)
            } catch {
                logger?.error("Failed to add outgoing ICE candidate: \(error)")
            }
        }
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChange newState: RTCIceConnectionState
    ) {
        if newState == .failed {
            peerConnection.restartIce()
        }
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didStartReceivingOn transceiver: RTCRtpTransceiver
    ) {
        var oldTransceiver: RTCRtpTransceiver?

        do {
            switch transceiver.mediaType {
            case .audio:
                if transceiver != mainAudioTransceiver {
                    try transceiver.sync(with: mainAudioTransceiver)
                    oldTransceiver = mainAudioTransceiver
                    mainAudioTransceiver = transceiver
                }
            case .video:
                let presentationMid = connection.mid(for: presentationVideoTransceiver)
                if let presentationVideoTransceiver, presentationMid == transceiver.mid {
                    if transceiver != presentationVideoTransceiver {
                        try transceiver.sync(with: presentationVideoTransceiver)
                        oldTransceiver = presentationVideoTransceiver
                        self.presentationVideoTransceiver = transceiver
                    }
                } else {
                    if transceiver != mainVideoTransceiver {
                        try transceiver.sync(with: mainVideoTransceiver)
                        oldTransceiver = mainVideoTransceiver
                        mainVideoTransceiver = transceiver
                    }
                }
            case .data, .unsupported:
                break
            @unknown default:
                break
            }
        } catch {
            logger?.error("Failed to replace transceiver: \(error)")
        }

        if let oldTransceiver, oldTransceiver.mid.isEmpty {
            connection.stopTransceiver(oldTransceiver)
        }
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didAdd rtpReceiver: RTCRtpReceiver,
        streams mediaStreams: [RTCMediaStream]
    ) {
        let track = rtpReceiver.track as? RTCVideoTrack

        if rtpReceiver.receiverId == mainAudioTransceiver?.receiver.receiverId {
            mainAudioTransceiver?.setSenderStreams(mediaStreams)
        } else if rtpReceiver.receiverId == mainVideoTransceiver?.receiver.receiverId {
            mainVideoTransceiver?.setSenderStreams(mediaStreams)
            remoteVideoTracks.setMainTrack(track.map { WebRTCVideoTrack(rtcTrack: $0) })
        } else if rtpReceiver.receiverId == presentationVideoTransceiver?.receiver.receiverId {
            presentationVideoTransceiver?.setSenderStreams(mediaStreams)
        }
    }
}

// MARK: - DataSender

extension WebRTCMediaConnection: DataSender {
    func send(_ data: Data) async throws -> Bool {
        guard let localDataChannel else {
            logger?.warn("Data channel - no local data channel created.")
            return false
        }

        let buffer = RTCDataBuffer(data: data, isBinary: false)
        let result = localDataChannel.sendData(buffer)
        logger?.debug("Data channel - did send data, success=\(result).")
        return result
    }
}

// MARK: - RTCDataChannelDelegate

extension WebRTCMediaConnection: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        let state = DataChannelState(dataChannel.readyState)
        logger?.debug("Data channel - did change state: \(state)")
    }

    func dataChannel(
        _ dataChannel: RTCDataChannel,
        didReceiveMessageWith buffer: RTCDataBuffer
    ) {
        Task {
            do {
                let result = try await signalingChannel.data?.receiver?.receive(buffer.data)
                logger?.debug("Data channel - did receive data, success=\(result == true).")
            } catch {
                logger?.error("Data channel - failed to process incoming data: \(error)")
            }
        }
    }
}
// swiftlint:enable file_length
