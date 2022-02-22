#if targetEnvironment(simulator)

import WebRTC

final class WebRTCVideoEncoderFactoryVP8: NSObject, RTCVideoEncoderFactory {
    func createEncoder(_ info: RTCVideoCodecInfo) -> RTCVideoEncoder? {
        info.name == kRTCVideoCodecVp8Name ? RTCVideoEncoderVP8.vp8Encoder() : nil
    }

    func supportedCodecs() -> [RTCVideoCodecInfo] {
        [RTCVideoCodecInfo(name: kRTCVideoCodecVp8Name)]
    }
}

#endif
