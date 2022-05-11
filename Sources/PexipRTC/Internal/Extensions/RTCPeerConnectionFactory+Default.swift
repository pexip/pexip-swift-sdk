import WebRTC

extension RTCPeerConnectionFactory {
    static func defaultFactory() -> RTCPeerConnectionFactory {
        RTCInitializeSSL()
        #if targetEnvironment(simulator) || os(macOS)
        let videoEncoderFactory = VideoEncoderFactoryVP8()
        let videoDecoderFactory = VideoDecoderFactoryVP8()
        #else
        let videoEncoderFactory = RTCVideoEncoderFactoryH264()
        let videoDecoderFactory = RTCVideoDecoderFactoryH264()
        #endif
        return RTCPeerConnectionFactory(
            encoderFactory: videoEncoderFactory,
            decoderFactory: videoDecoderFactory
        )
    }
}
