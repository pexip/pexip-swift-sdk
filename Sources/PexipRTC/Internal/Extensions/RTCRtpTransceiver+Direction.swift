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
}
