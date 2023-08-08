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

// swiftlint:disable type_body_length file_length
actor WebRTCMediaConnection: MediaConnection, DataSender {
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
    private var ackReceived = false
    private var isPolitePeer = false
    private var incomingIceCandidates = [RTCIceCandidate]()
    private var outgoingIceCandidates = [RTCIceCandidate]()
    private var negotiationTask: Task<Void, Error>?
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

        try await negotiate {
            try await $0?.sendOffer()
        }
    }

    func stop() async {
        await peerConnection.close()

        cancellables.removeAll()
        mainLocalAudioTrack = nil
        signalingChannel.data?.sender = nil

        setRemoteTrack(nil, content: .mainVideo)
        setRemoteTrack(nil, content: .presentationVideo)

        started = false
        isMakingOffer = false
        ackReceived = false
        isPolitePeer = false
        incomingIceCandidates.removeAll()
        outgoingIceCandidates.removeAll()
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

    // MARK: - MediaConnection (preferences)

    func setMainDegradationPreference(_ preference: DegradationPreference) async {
        await peerConnection.setDegradationPreference(preference, for: .mainVideo)
    }

    func setPresentationDegradationPreference(_ preference: DegradationPreference) async {
        await peerConnection.setDegradationPreference(preference, for: .presentationVideo)
    }

    func setMaxBitrate(_ bitrate: Bitrate) async {
        await peerConnection.setMaxBitrate(bitrate)
    }

    @discardableResult
    func dtmf(signals: DTMFSignals) async throws -> Bool {
        try await signalingChannel.dtmf(signals: signals)
    }

    // MARK: - Data channel

    func send(_ data: Data) async throws -> Bool {
        try await peerConnection.send(data)
    }

    private func receive(_ data: Data) async throws {
        let result = try await signalingChannel.data?.receiver?.receive(data)
        logger?.debug("Data channel - did receive data, success=\(result == true).")
    }

    // MARK: - Events

    private func subscribeToEvents() {
        peerConnection.eventPublisher.sink { [weak self] event in
            Task { [weak self] in
                await self?.handleEvent(event)
            }
        }.store(in: &cancellables)

        secureCheckCode.sink { [weak self] value in
            self?.logger?.debug("Secure Check Code: \(value)")
        }.store(in: &cancellables)

        signalingChannel.eventPublisher.sink { [weak self] event in
            Task { [weak self] in
                await self?.handleEvent(event)
            }
        }.store(in: &cancellables)
    }

    private func handleEvent(_ event: PeerConnection.Event) async {
        do {
            switch event {
            case .shouldNegotiate:
                try await negotiate {
                    try await $0?.sendOffer()
                }
            case .newPeerConnectionState(let newState):
                stateSubject.send(newState)
                #if os(iOS)
                if newState == .connected {
                    mainLocalAudioTrack?.speakerOn()
                }
                #endif
            case .newCandidate(let candidate):
                if isMakingOffer {
                    outgoingIceCandidates.append(candidate)
                } else {
                    await addOutgoingIceCandidate(candidate)
                }
            case let .receiverTrackUpdated(track, content):
                setRemoteTrack(track, content: content)
            case let .dataReceived(data):
                try await receive(data)
            }
        } catch {
            logger?.error("Failed to handle peer connection event: \(error)")
        }
    }

    private func handleEvent(_ event: SignalingEvent) async {
        do {
            switch event {
            case .newOffer(let sdp):
                try await negotiate {
                    await $0?.receiveNewOffer(sdp)
                }
            case let .newCandidate(candidate, mid):
                await receiveCandidate(candidate, mid: mid)
            }
        } catch {
            logger?.error("Failed to handle signaling event: \(error)")
        }
    }

    // MARK: - Negotiation

    private func negotiate(
        _ task: @escaping (WebRTCMediaConnection?) async throws -> Void
    ) async throws {
        negotiationTask = Task { [weak self, negotiationTask] in
            _ = await negotiationTask?.result
            try await task(self)
        }
        try await negotiationTask?.result.get()
    }

    private func sendOffer() async throws {
        isMakingOffer = true
        logger?.debug("Outgoing offer - initiated")

        do {
            guard let offer = try await peerConnection.setLocalDescription() else {
                return
            }

            if let answer = try await signalingChannel.sendOffer(
                callType: "WEBRTC",
                description: offer.sdp,
                presentationInMain: config.presentationInMain
            ) {
                try await peerConnection.setRemoteAnswer(answer)
                try await ack(nil)
            } else {
                isPolitePeer = true
            }

            isMakingOffer = false
            await addOutgoingIceCandidatesIfNeeded()
            logger?.debug("Outgoing offer - received answer, isPolitePeer=\(isPolitePeer)")
        } catch {
            isMakingOffer = false
            logger?.error("Outgoing offer - failed to send new offer: \(error)")
            throw error
        }
    }

    private func receiveNewOffer(_ offer: String) async {
        logger?.debug("Incoming offer - initiated")

        guard await canReceiveOffer else {
            logger?.debug("Incoming offer - ignored")
            return
        }

        do {
            try await peerConnection.setRemoteOffer(offer)

            if let answer = try await peerConnection.setLocalDescription() {
                try await ack(answer.sdp)
            }

            logger?.debug("Incoming offer - sent answer")
        } catch {
            incomingIceCandidates.removeAll()
            logger?.error("Incoming offer - failed to accept: \(error)")
        }
    }

    private func ack(_ description: String?) async throws {
        try await signalingChannel.ack(description)
        ackReceived = true
        await addIncomingIceCandidatesIfNeeded()
    }

    private func receiveCandidate(_ candidate: String, mid: String?) async {
        guard let mid = mid.flatMap({ Int32($0) }), !candidate.isEmpty else {
            return
        }

        let candidate = RTCIceCandidate(
            sdp: candidate,
            sdpMLineIndex: mid,
            sdpMid: "\(mid)"
        )

        if ackReceived {
            await addIncomingIceCandidate(candidate)
        } else {
            incomingIceCandidates.append(candidate)
        }
    }

    private func addIncomingIceCandidatesIfNeeded() async {
        let incomingIceCandidates = self.incomingIceCandidates
        self.incomingIceCandidates.removeAll()

        await withTaskGroup(of: Void.self) { group in
            for candidate in incomingIceCandidates {
                group.addTask { [weak self] in
                    await self?.addIncomingIceCandidate(candidate)
                }
            }
            await group.waitForAll()
        }
    }

    private func addIncomingIceCandidate(_ candidate: RTCIceCandidate) async {
        do {
            try await peerConnection.addCandidate(candidate)
            logger?.debug("New incoming ICE candidate added")
        } catch {
            if await canReceiveOffer {
                logger?.error("Failed to add new incoming ICE candidate")
            }
        }
    }

    private func addOutgoingIceCandidatesIfNeeded() async {
        let outgoingIceCandidates = self.outgoingIceCandidates
        self.outgoingIceCandidates.removeAll()

        await withTaskGroup(of: Void.self) { group in
            for candidate in outgoingIceCandidates {
                group.addTask { [weak self] in
                    await self?.addOutgoingIceCandidate(candidate)
                }
            }
            await group.waitForAll()
        }
    }

    private func addOutgoingIceCandidate(_ candidate: RTCIceCandidate) async {
        do {
            try await signalingChannel.addCandidate(candidate.sdp, mid: candidate.sdpMid)
            logger?.debug("New outgoing ICE candidate added")
        } catch {
            logger?.error("Failed to add outgoing ICE candidate: \(error)")
        }
    }

    private func setRemoteTrack(_ track: RTCMediaStreamTrack?, content: MediaContent) {
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
// swiftlint:enable type_body_length file_length
