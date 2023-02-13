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

    func sync(with transceiver: RTCRtpTransceiver?) throws {
        guard let transceiver else {
            return
        }

        try setDirection(transceiver.direction)

        if let track = transceiver.sender.track {
            sender.track = track
        }
    }

    func setSenderStreams(_ streams: [RTCMediaStream]) {
        sender.streamIds = streams.map(\.streamId)
    }
}
