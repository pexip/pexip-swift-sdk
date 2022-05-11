import WebRTC

final class VideoDecoderFactoryVP8: NSObject, RTCVideoDecoderFactory {
    func createDecoder(_ info: RTCVideoCodecInfo) -> RTCVideoDecoder? {
        info.name == kRTCVp8CodecName ? RTCVideoDecoderVP8.vp8Decoder() : nil
    }

    func supportedCodecs() -> [RTCVideoCodecInfo] {
        [RTCVideoCodecInfo(name: kRTCVp8CodecName)]
    }
}
