//
// Copyright 2023 Pexip AS
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

// swiftlint:disable type_body_length
actor PeerConnection {
    enum Event {
        case shouldNegotiate
        case newPeerConnectionState(MediaConnectionState)
        case newCandidate(RTCIceCandidate)
        case receiverTrackUpdated(RTCMediaStreamTrack?, content: MediaContent)
        case dataReceived(Data)
    }

    nonisolated let eventPublisher: AnyPublisher<Event, Never>
    nonisolated let secureCheckCode: AnyPublisher<String, Never>
    private(set) var signalingState: SignalingState

    private let connection: RTCPeerConnection
    private let connectionDelegateProxy: PeerConnectionDelegateProxy
    private let dataChannelDelegateProxy: DataChannelDelegateProxy
    private let logger: Logger?
    private var shouldRenegotiate = false
    private var transceivers = [MediaContent: Transceiver]()
    private var degradationPreferences = [MediaContent: DegradationPreference]()
    private var bitrate = Bitrate.bps(0)
    private var dataChannel: RTCDataChannel?
    private let fingerprintStore = FingerprintStore()
    private let eventSubject = PassthroughSubject<Event, Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        factory: RTCPeerConnectionFactory,
        configuration: RTCConfiguration,
        logger: Logger? = nil
    ) {
        connectionDelegateProxy = .init(logger: logger)
        dataChannelDelegateProxy = .init(logger: logger)

        guard let connection = factory.peerConnection(
            with: configuration,
            constraints: RTCMediaConstraints(
                mandatoryConstraints: nil,
                optionalConstraints: nil
            ),
            delegate: connectionDelegateProxy
        ) else {
            fatalError("Could not create new RTCPeerConnection")
        }

        self.connection = connection
        self.logger = logger
        self.signalingState = SignalingState(connection.signalingState)
        self.eventPublisher = eventSubject.eraseToAnyPublisher()
        self.secureCheckCode = fingerprintStore.secureCheckCode.$value.eraseToAnyPublisher()

        Task {
            await subscribeToEvents()
        }
    }

    deinit {
        connection.close()
        dataChannel?.close()
    }

    // MARK: - Internal

    func close() {
        cancellables.removeAll()
        transceivers.removeAll()

        connection.close()

        dataChannel?.close()
        dataChannel = nil

        fingerprintStore.reset()
        shouldRenegotiate = false
    }

    func setLocalDescription() async throws -> RTCSessionDescription? {
        try await connection.setLocalDescription()

        for transceiver in transceivers.values where transceiver.mid == nil {
            transceiver.syncMid()
        }

        syncTransceivers()

        let description = connection.localDescription.map {
            RTCSessionDescription(
                type: $0.type,
                sdp: SessionDescriptionManager(sdp: $0.sdp).mangle(
                    bitrate: bitrate,
                    mids: transceivers.compactMapValues(\.mid)
                )
            )
        }

        if let description {
            fingerprintStore.setLocalFingerprints(fingerprints(from: description))
        }

        return description
    }

    func setRemoteOffer(_ offer: String) async throws {
        try await setRemoteDescription(RTCSessionDescription(type: .offer, sdp: offer))
    }

    func setRemoteAnswer(_ answer: String) async throws {
        try await setRemoteDescription(RTCSessionDescription(type: .answer, sdp: answer))
    }

    func setRemoteDescription(_ description: RTCSessionDescription) async throws {
        let description = RTCSessionDescription(
            type: description.type,
            sdp: SessionDescriptionManager(sdp: description.sdp).mangle(
                bitrate: bitrate
            )
        )
        try await connection.setRemoteDescription(description)
        fingerprintStore.setRemoteFingerprints(fingerprints(from: description))
    }

    func addCandidate(_ candidate: RTCIceCandidate) async throws {
        try await connection.add(candidate)
    }

    func setDirection(
        _ direction: RTCRtpTransceiverDirection,
        for content: MediaContent
    ) throws {
        try transceiver(
            for: content,
            initIfNeeded: .init(direction: direction)
        )?.setDirection(direction)
    }

    func send(
        _ content: MediaContent,
        from track: WebRTCLocalTrack?,
        initIfNeeded initValue: RTCRtpTransceiverInit? = nil,
        onCapture: @escaping (Bool) async throws -> Void
    ) throws {
        let transceiver = transceiver(
            for: content,
            initIfNeeded: track != nil ? initValue : nil
        )
        try transceiver?.send(from: track, onCapture: { value in
            Task {
                try await onCapture(value)
            }
        })
        if let degradationPreference = degradationPreferences[content] {
            transceiver?.setDegradationPreference(degradationPreference)
        }
    }

    func send(_ data: Data) throws -> Bool {
        guard let dataChannel else {
            logger?.warn("Data channel - no local data channel created.")
            return false
        }

        let buffer = RTCDataBuffer(data: data, isBinary: false)
        let result = dataChannel.sendData(buffer)
        logger?.debug("Data channel - did send data, success=\(result).")
        return result
    }

    func receive(_ content: MediaContent, receive: Bool) throws {
        try transceiver(
            for: content,
            initIfNeeded: .init(direction: .recvOnly)
        )?.receive(receive)
    }

    func setDegradationPreference(
        _ preference: DegradationPreference,
        for content: MediaContent
    ) {
        degradationPreferences[content] = preference
        transceivers[content]?.setDegradationPreference(preference)
    }

    func setMaxBitrate(_ bitrate: Bitrate) {
        guard bitrate != self.bitrate else { return }
        self.bitrate = bitrate
        connection.restartIce()
    }

    func createDataChannel(withId id: Int32) {
        let config = RTCDataChannelConfiguration()
        config.isNegotiated = true
        config.channelId = id
        dataChannel = connection.dataChannel(
            forLabel: "pexChannel",
            configuration: config
        )
        dataChannel?.delegate = dataChannelDelegateProxy
        logger?.debug("Data channel - new data channel created.")
    }

    // MARK: - Events

    private func subscribeToEvents() {
        connectionDelegateProxy.eventPublisher.sink { [weak self] event in
            Task { [weak self] in
                await self?.handleEvent(event)
            }
        }.store(in: &cancellables)

        dataChannelDelegateProxy.onDataBuffer = { [weak self] buffer in
            Task { [weak self] in
                self?.eventSubject.send(.dataReceived(buffer.data))
            }
        }
    }

    private func handleEvent(_ event: PeerConnectionDelegateProxy.Event) {
        switch event {
        case .shouldNegotiate:
            onShouldNegotiate()
        case .newPeerConnectionState(let state):
            eventSubject.send(.newPeerConnectionState(state))
        case .newSignalingState(let state):
            signalingState = state
        case .newIceConnectionState(let state):
            if state == .failed {
                connection.restartIce()
            }
        case .newCandidate(let candidate):
            eventSubject.send(.newCandidate(candidate))
        case .startedReceivingOnTranceiver(let transceiver):
            syncTransceiver(transceiver)
        case .receiverAdded(let receiver):
            onReceiver(receiver, removed: false)
        case .receiverRemoved(let receiver):
            onReceiver(receiver, removed: true)
        }
    }

    private func onShouldNegotiate() {
        guard ![.closed, .disconnected].contains(connection.connectionState) else {
            return
        }

        // Skip the first call to negotiateIfNeeded() since it's
        // called right after RTCPeerConnection creation,
        // and we're still not ready for negotiation.
        if shouldRenegotiate {
            eventSubject.send(.shouldNegotiate)
        } else {
            shouldRenegotiate = true
        }
    }

    private func onReceiver(_ receiver: RTCRtpReceiver, removed: Bool) {
        guard let (content, transceiver) = transceivers.first(where: { _, transceiver in
            receiver.receiverId == transceiver.receiverId
        }) else {
            return
        }

        let track = removed || !transceiver.canReceive ? nil : receiver.track
        eventSubject.send(.receiverTrackUpdated(track, content: content))
    }

    private func syncTransceivers() {
        for transceiver in connection.transceivers {
            syncTransceiver(transceiver)
        }
    }

    private func syncTransceiver(_ newTransceiver: RTCRtpTransceiver) {
        do {
            try transceivers.values
                .first(where: { $0.mid == newTransceiver.mid })?
                .sync(with: newTransceiver)
        } catch {
            logger?.error("Failed to replace transceiver: \(error)")
        }
    }

    // MARK: - Helpers

    private func transceiver(
        for content: MediaContent,
        initIfNeeded initValue: RTCRtpTransceiverInit? = nil
    ) -> Transceiver? {
        if let transceiver = transceivers[content] {
            return transceiver
        } else if let initValue {
            let transceiver = connection.addTransceiver(
                of: content.mediaType,
                init: initValue
            ).map(Transceiver.init)

            transceivers[content] = transceiver

            return transceiver
        } else {
            return nil
        }
    }

    private func fingerprints(from description: RTCSessionDescription) -> [Fingerprint] {
        SessionDescriptionManager(sdp: description.sdp).extractFingerprints()
    }
}
// swiftlint:enable type_body_length
