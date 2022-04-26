import WebRTC

extension RTCRtpTransceiverInit {
    convenience init(direction: RTCRtpTransceiverDirection) {
        self.init()
        self.direction = direction
    }
}
