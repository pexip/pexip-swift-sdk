//
// Copyright 2022 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import WebRTC

final class VideoDecoderFactoryVP8: NSObject, RTCVideoDecoderFactory {
    func createDecoder(_ info: RTCVideoCodecInfo) -> RTCVideoDecoder? {
        info.name == kRTCVp8CodecName ? RTCVideoDecoderVP8.vp8Decoder() : nil
    }

    func supportedCodecs() -> [RTCVideoCodecInfo] {
        [RTCVideoCodecInfo(name: kRTCVp8CodecName)]
    }
}
