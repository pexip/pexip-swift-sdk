//
// Copyright 2022 Pexip AS
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

import WebRTC
import PexipCore
import PexipMedia

// MARK: - Delegate

protocol PeerConnectionDelegate: AnyObject {
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection)
    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChange newState: MediaConnectionState
    )
    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didGenerate candidate: RTCIceCandidate
    )
    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChange newState: RTCIceConnectionState
    )
    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didStartReceivingOn transceiver: RTCRtpTransceiver
    )
    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didAdd rtpReceiver: RTCRtpReceiver,
        streams mediaStreams: [RTCMediaStream]
    )
}

// MARK: - Proxy

final class PeerConnectionDelegateProxy: NSObject, RTCPeerConnectionDelegate {
    weak var delegate: PeerConnectionDelegate?
    private let logger: Logger?

    init(logger: Logger?) {
        self.logger = logger
    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        logger?.debug("Peer connection - should negotiate")
        delegate?.peerConnectionShouldNegotiate(peerConnection)
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChange newState: RTCPeerConnectionState
    ) {
        let state = MediaConnectionState(newState)
        logger?.debug("Peer connection - new peer connection state: \(state)")
        delegate?.peerConnection(peerConnection, didChange: state)
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didGenerate candidate: RTCIceCandidate
    ) {
        logger?.debug("Peer connection - did generate local ICE candidate")
        delegate?.peerConnection(peerConnection, didGenerate: candidate)
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChange stateChanged: RTCSignalingState
    ) {
        let state = SignalingState(stateChanged)
        logger?.debug("Peer connection - new signaling state: \(state)")
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
        delegate?.peerConnection(peerConnection, didChange: newState)
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
        delegate?.peerConnection(peerConnection, didAdd: rtpReceiver, streams: mediaStreams)
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didStartReceivingOn transceiver: RTCRtpTransceiver
    ) {
        logger?.debug("Peer connection - did start receiving on transceiver")
        delegate?.peerConnection(peerConnection, didStartReceivingOn: transceiver)
    }
}
