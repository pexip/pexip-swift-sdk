import WebRTC

extension RTCRtpTransceiver {
    func setDirection(_ direction: RTCRtpTransceiverDirection) throws {
        guard self.direction != direction else {
            return
        }

        var error: NSError?
        setDirection(direction, error: &error)

        if let error {
            throw error
        }
    }

    func sync(with transceiver: RTCRtpTransceiver?) throws {
        guard let transceiver else {
            return
        }

        try setDirection(transceiver.direction)

        if let track = transceiver.sender.track {
            sender.track = track
        }
    }

    func setSenderStreams(_ streams: [RTCMediaStream]) {
        sender.streamIds = streams.map(\.streamId)
    }
}
