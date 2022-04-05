import WebRTC

final class WebRTCVideoEncoderFactoryVP8: NSObject, RTCVideoEncoderFactory {
    func createEncoder(_ info: RTCVideoCodecInfo) -> RTCVideoEncoder? {
        info.name == kRTCVp8CodecName ? RTCVideoEncoderVP8.vp8Encoder() : nil
    }

    func supportedCodecs() -> [RTCVideoCodecInfo] {
        [RTCVideoCodecInfo(name: kRTCVp8CodecName)]
    }
}
