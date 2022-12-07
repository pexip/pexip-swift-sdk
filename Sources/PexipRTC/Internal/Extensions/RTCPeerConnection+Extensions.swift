import WebRTC

extension RTCPeerConnection {
    /// Naive way of obtaining the transciever mid.
    func mid(for transceiver: RTCRtpTransceiver?) -> String? {
        guard let transceiver else {
            return nil
        }

        if transceiver.mid.isEmpty {
            return transceivers.firstIndex(of: transceiver).map { "\($0)" }
        } else {
            return transceiver.mid
        }
    }

    func stopTransceiver(_ transceiver: RTCRtpTransceiver) {
        transceiver.stopInternal()
        removeTrack(transceiver.sender)
    }
}
