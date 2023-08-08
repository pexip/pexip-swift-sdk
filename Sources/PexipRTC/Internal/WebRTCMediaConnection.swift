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
actor WebRTCMediaConnection: MediaConnection {
    let remoteVideoTracks = RemoteVideoTracks()

    nonisolated var statePublisher: AnyPublisher<MediaConnectionState, Never> {
        stateSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    nonisolated var secureCheckCode: AnyPublisher<String, Never> {
        peerConnection.secureCheckCode
    }

    private let peerConnection: PeerConnection
    private let config: MediaConnectionConfig
    private let logger: Logger?
    private var mainLocalAudioTrack: WebRTCLocalAudioTrack?
    private var signalingChannel: SignalingChannel { config.signaling }
    private var started = false
    private var isMakingOffer = false
    private var isReceivingOffer = false
    private var isPolitePeer = false
    private var shouldAck = true
    private var incomingIceCandidates = [RTCIceCandidate]()
    private var outgoingIceCandidates = [RTCIceCandidate]()
    private let stateSubject = PassthroughSubject<MediaConnectionState, Never>()
    private var cancellables = Set<AnyCancellable>()

    private var canReceiveOffer: Bool {
        get async {
            let state = await peerConnection.signalingState
            let hasOfferCollision = isMakingOffer || state != .stable
            return isPolitePeer || !hasOfferCollision
        }
    }

    // MARK: - Init

    init(
        config: MediaConnectionConfig,
        factory: RTCPeerConnectionFactory,
        logger: Logger? = nil
    ) {
        peerConnection = PeerConnection(
            factory: factory,
            configuration: .defaultConfiguration(
                withIceServers: config.iceServers,
                dscp: config.dscp
            ),
            logger: logger
        )
        self.config = config
        self.logger = logger
        Task {
            await subscribeToEvents()
        }
    }

    // MARK: - MediaConnection (tracks)

    func setMainAudioTrack(_ audioTrack: LocalAudioTrack?) async throws {
        mainLocalAudioTrack = audioTrack.valueOrNil(WebRTCLocalAudioTrack.self)
        try await peerConnection.send(
            .mainAudio,
            from: mainLocalAudioTrack,
            initIfNeeded: .init(direction: .sendOnly),
            onCapture: { [weak self] isCapturing in
                try await self?.signalingChannel.muteAudio(!isCapturing)
            }
        )
    }

    func setMainVideoTrack(_ videoTrack: CameraVideoTrack?) async throws {
        try await peerConnection.send(
            .mainVideo,
            from: videoTrack.valueOrNil(WebRTCCameraVideoTrack.self),
            initIfNeeded: .init(direction: .sendOnly),
            onCapture: { [weak self] isCapturing in
                try await self?.signalingChannel.muteVideo(!isCapturing)
            }
        )
    }

    func setScreenMediaTrack(_ screenMediaTrack: ScreenMediaTrack?) async throws {
        try await peerConnection.send(
            .presentationVideo,
            from: screenMediaTrack.valueOrNil(WebRTCScreenMediaTrack.self),
            onCapture: { [weak self] isCapturing in
                do {
                    if isCapturing {
                        try await self?.signalingChannel.takeFloor()
                    } else {
                        try await self?.signalingChannel.releaseFloor()
                    }
                } catch {
                    self?.logger?.error("Error on takeFloow/releaseFloor: \(error)")
                }
            }
        )
    }

    // MARK: - MediaConnection (lifecycle)

    func start() async throws {
        guard !started else {
            return
        }

        started = true
        try await peerConnection.setDirection(.inactive, for: .presentationVideo)

        if let dataChannelId = signalingChannel.data?.id {
            await peerConnection.createDataChannel(withId: dataChannelId)
            signalingChannel.data?.sender = self
        }

        try await sendOffer()
    }

    func stop() async {
        await peerConnection.close()

        cancellables.removeAll()
        mainLocalAudioTrack = nil

        remoteVideoTracks.setMainTrack(nil)
        remoteVideoTracks.setPresentationTrack(nil)

        started = false
        isMakingOffer = false
        isReceivingOffer = false
        isPolitePeer = false
        shouldAck = true
        incomingIceCandidates.removeAll()
        outgoingIceCandidates.removeAll()

        signalingChannel.data?.sender = nil
    }

    func receiveMainRemoteAudio(_ receive: Bool) async throws {
        try await peerConnection.receive(.mainAudio, receive: receive)
    }

    func receiveMainRemoteVideo(_ receive: Bool) async throws {
        try await peerConnection.receive(.mainVideo, receive: receive)
    }

    func receivePresentation(_ receive: Bool) async throws {
        if !config.presentationInMain {
            try await peerConnection.receive(.presentationVideo, receive: receive)
        }
    }

    // MARK: - Other

    @discardableResult
    func dtmf(signals: DTMFSignals) async throws -> Bool {
        try await signalingChannel.dtmf(signals: signals)
    }

    func setMainDegradationPreference(_ preference: DegradationPreference) async {
        await peerConnection.setDegradationPreference(preference, for: .mainVideo)
    }

    func setPresentationDegradationPreference(_ preference: DegradationPreference) async {
        await peerConnection.setDegradationPreference(preference, for: .presentationVideo)
    }

    func setMaxBitrate(_ bitrate: Bitrate) async {
        await peerConnection.setMaxBitrate(bitrate)
    }
}

// MARK: - Private

private extension WebRTCMediaConnection {
    func sendOffer() async throws {
        isMakingOffer = true

        defer {
            isMakingOffer = false
        }

        logger?.debug("Outgoing offer - initiated")

        do {
            guard let localDescription = try await peerConnection.setLocalDescription() else {
                return
            }

            if let remoteDescription = try await config.signaling.sendOffer(
                callType: "WEBRTC",
                description: localDescription.sdp,
                presentationInMain: config.presentationInMain
            ).map({
                RTCSessionDescription(type: .answer, sdp: $0)
            }) {
                try await peerConnection.setRemoteDescription(remoteDescription)
                if shouldAck {
                    shouldAck = false
                    try await config.signaling.ack()
                }
            } else {
                isPolitePeer = true
            }

            isMakingOffer = false
            try await addOutgoingIceCandidatesIfNeeded()
            logger?.debug("Outgoing offer - received answer, isPolitePeer=\(isPolitePeer)")
        } catch {
            logger?.error("Outgoing offer - failed to send new offer: \(error)")
            outgoingIceCandidates.removeAll()
            throw error
        }
    }

    func receiveNewOffer(_ offer: String) async {
        isReceivingOffer = true

        defer {
            isReceivingOffer = false
        }

        logger?.debug("Incoming offer - received")
        guard await canReceiveOffer else {
            logger?.debug("Incoming offer - ignored")
            return
        }

        do {
            let remoteDescription = RTCSessionDescription(type: .offer, sdp: offer)
            try await peerConnection.setRemoteDescription(remoteDescription)

            if let localDescription = try await peerConnection.setLocalDescription() {
                try await config.signaling.sendAnswer(localDescription.sdp)
            }

            isReceivingOffer = false
            try await addIncomingIceCandidatesIfNeeded()
            logger?.debug("Incoming offer - sent answer")
        } catch {
            incomingIceCandidates.removeAll()
            logger?.error("Incoming offer - failed to accept: \(error)")
        }
    }

    func receiveCandidate(_ candidate: String, mid: String?) async {
        guard !candidate.isEmpty else {
            return
        }
        let candidate = RTCIceCandidate(
            sdp: candidate,
            sdpMLineIndex: mid.flatMap({ Int32($0) }) ?? 0,
            sdpMid: mid
        )

        do {
            if isReceivingOffer {
                incomingIceCandidates.append(candidate)
            } else {
                try await peerConnection.addCandidate(candidate)
                logger?.debug("New incoming ICE candidate added")
            }
        } catch {
            if await canReceiveOffer {
                logger?.error("Failed to add new incoming ICE candidate")
            }
        }
    }

    func addIncomingIceCandidatesIfNeeded() async throws {
        let incomingIceCandidates = self.incomingIceCandidates
        self.incomingIceCandidates.removeAll()

        for candidate in incomingIceCandidates {
            try await peerConnection.addCandidate(candidate)
            logger?.debug("New incoming ICE candidate added")
        }
    }

    func addOutgoingIceCandidatesIfNeeded() async throws {
        let outgoingIceCandidates = self.outgoingIceCandidates
        self.outgoingIceCandidates.removeAll()

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

    func subscribeToEvents() {
        peerConnection.eventPublisher.sink { event in
            Task { @MainActor [weak self] in
                await self?.handleEvent(event)
            }
        }.store(in: &cancellables)

        secureCheckCode.sink { [weak self] value in
            self?.logger?.debug("Secure Check Code: \(value)")
        }.store(in: &cancellables)

        config.signaling.eventPublisher.sink { event in
            Task { [weak self] in
                await self?.handleEvent(event)
            }
        }.store(in: &cancellables)
    }

    func handleEvent(_ event: PeerConnection.Event) async {
        switch event {
        case .shouldNegotiate:
            if !isReceivingOffer {
                try? await sendOffer()
            }
        case .newPeerConnectionState(let newState):
            stateSubject.send(newState)
            #if os(iOS)
            if newState == .connected {
                mainLocalAudioTrack?.speakerOn()
            }
            #endif
        case .newCandidate(let candidate):
            await onNewCandidate(candidate)
        case let .receiverTrackUpdated(track, content):
            onReceiverTrack(track, content: content)
        case let .dataReceived(data):
            do {
                let result = try await signalingChannel.data?.receiver?.receive(data)
                logger?.debug("Data channel - did receive data, success=\(result == true).")
            } catch {
                logger?.error("Data channel - failed to process incoming data: \(error)")
            }
        }
    }

    func handleEvent(_ event: SignalingEvent) async {
        switch event {
        case .newOffer(let sdp):
            await receiveNewOffer(sdp)
        case let .newCandidate(candidate, mid):
            await receiveCandidate(candidate, mid: mid)
        }
    }

    func onNewCandidate(_ candidate: RTCIceCandidate) async {
        guard !isMakingOffer else {
            outgoingIceCandidates.append(candidate)
            return
        }

        do {
            try await addOutgoingIceCandidate(candidate)
        } catch {
            logger?.error("Failed to add outgoing ICE candidate: \(error)")
        }
    }

    func onReceiverTrack(_ track: RTCMediaStreamTrack?, content: MediaContent) {
        func videoTrack() -> WebRTCVideoTrack? {
            (track as? RTCVideoTrack).map { WebRTCVideoTrack(rtcTrack: $0) }
        }

        switch content {
        case .mainVideo:
            remoteVideoTracks.setMainTrack(videoTrack())
        case .presentationVideo:
            remoteVideoTracks.setPresentationTrack(videoTrack())
        default:
            break
        }
    }
}

// MARK: - DataSender

extension WebRTCMediaConnection: DataSender {
    func send(_ data: Data) async throws -> Bool {
        try await peerConnection.send(data)
    }
}

// swiftlint:enable file_length
