//
// Copyright 2022-2023 Pexip AS
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

extension RTCPeerConnection {
    /// Naive way of obtaining the transciever mid.
    func mid(for transceiver: RTCRtpTransceiver?) -> String? {
        guard let transceiver else {
            return nil
        }

        if transceiver.mid.isEmpty {
            return transceivers.firstIndex(of: transceiver).map { "\($0)" }
        } else {
            return transceiver.mid
        }
    }

    func addAudioTransceiver(_ direction: RTCRtpTransceiverDirection) -> RTCRtpTransceiver? {
        addTransceiver(of: .audio, init: .init(direction: direction))
    }

    func addVideoTransceiver(_ direction: RTCRtpTransceiverDirection) -> RTCRtpTransceiver? {
        addTransceiver(of: .video, init: .init(direction: direction))
    }

    func stopTransceiver(_ transceiver: RTCRtpTransceiver) {
        transceiver.stopInternal()
        removeTrack(transceiver.sender)
    }
}
