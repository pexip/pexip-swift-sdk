#if targetEnvironment(simulator)

import WebRTC

final class RTCVideoDecoderFactoryVP8: NSObject, RTCVideoDecoderFactory {
    func createDecoder(_ info: RTCVideoCodecInfo) -> RTCVideoDecoder? {
        info.name == kRTCVideoCodecVp8Name ? RTCVideoDecoderVP8.vp8Decoder() : nil
    }

    func supportedCodecs() -> [RTCVideoCodecInfo] {
        [RTCVideoCodecInfo(name: kRTCVideoCodecVp8Name)]
    }
}

#endif
