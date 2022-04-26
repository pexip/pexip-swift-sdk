import WebRTC

extension RTCPeerConnectionFactory {
    static let `default`: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        #if targetEnvironment(simulator) || os(macOS)
        let videoEncoderFactory = RTCVideoEncoderFactoryVP8()
        let videoDecoderFactory = RTCVideoDecoderFactoryVP8()
        #else
        let videoEncoderFactory = RTCVideoEncoderFactoryH264()
        let videoDecoderFactory = RTCVideoDecoderFactoryH264()
        #endif
        return RTCPeerConnectionFactory(
            encoderFactory: videoEncoderFactory,
            decoderFactory: videoDecoderFactory
        )
    }()
}
