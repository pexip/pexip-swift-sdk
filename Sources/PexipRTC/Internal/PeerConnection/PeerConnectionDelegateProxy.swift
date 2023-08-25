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

// MARK: - Proxy

final class PeerConnectionDelegateProxy: NSObject, RTCPeerConnectionDelegate {
    enum Event {
        case shouldNegotiate
        case newPeerConnectionState(MediaConnectionState)
        case newSignalingState(SignalingState)
        case newIceConnectionState(IceConnectionState)
        case newCandidate(RTCIceCandidate)
        case startedReceivingOnTranceiver(RTCRtpTransceiver)
        case receiverAdded(RTCRtpReceiver)
        case receiverRemoved(RTCRtpReceiver)
    }

    var eventPublisher: AnyPublisher<Event, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    private var eventSubject = PassthroughSubject<Event, Never>()
    private let logger: Logger?

    // MARK: - Init

    init(logger: Logger?) {
        self.logger = logger
    }

    // MARK: - RTCPeerConnectionDelegate

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        logger?.debug("Peer connection - should negotiate")
        eventSubject.send(.shouldNegotiate)
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChange newState: RTCPeerConnectionState
    ) {
        let state = MediaConnectionState(newState)
        logger?.debug("Peer connection - new peer connection state: \(state)")
        eventSubject.send(.newPeerConnectionState(state))
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didGenerate candidate: RTCIceCandidate
    ) {
        logger?.debug("Peer connection - did generate local ICE candidate")
        eventSubject.send(.newCandidate(candidate))
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChange stateChanged: RTCSignalingState
    ) {
        let state = SignalingState(stateChanged)
        logger?.debug("Peer connection - new signaling state: \(state)")
        eventSubject.send(.newSignalingState(state))
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didAdd stream: RTCMediaStream
    ) {
        logger?.debug("Peer connection - did add stream, id:\(stream.streamId)")
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didRemove stream: RTCMediaStream
    ) {
        logger?.debug("Peer connection - did remove stream")
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChange newState: RTCIceConnectionState
    ) {
        let state = IceConnectionState(newState)
        logger?.debug("Peer connection - new ICE connection state: \(state)")
        eventSubject.send(.newIceConnectionState(state))
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChange newState: RTCIceGatheringState
    ) {
        let state = IceGatheringState(newState)
        logger?.debug("Peer connection - new ICE gathering state: \(state)")
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didRemove candidates: [RTCIceCandidate]
    ) {
        let count = candidates.count
        logger?.debug("Peer connection - did remove \(count) ICE candidate(s)")
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didOpen dataChannel: RTCDataChannel
    ) {
        logger?.debug("Peer connection - did open data channel")
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didAdd rtpReceiver: RTCRtpReceiver,
        streams mediaStreams: [RTCMediaStream]
    ) {
        logger?.debug("Peer connection - did add rtpReceiver")
        eventSubject.send(.receiverAdded(rtpReceiver))
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didRemove rtpReceiver: RTCRtpReceiver
    ) {
        eventSubject.send(.receiverRemoved(rtpReceiver))
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didStartReceivingOn transceiver: RTCRtpTransceiver
    ) {
        logger?.debug("Peer connection - did start receiving on transceiver")
        eventSubject.send(.startedReceivingOnTranceiver(transceiver))
    }
}
