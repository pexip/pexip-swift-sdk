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

import PexipMedia
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

    func send(from track: RTCMediaStreamTrack?) throws {
        try send(track != nil)
        sender.track = track
    }

    func send(_ enabled: Bool) throws {
        if enabled {
            switch direction {
            case .inactive:
                try setDirection(.sendOnly)
            case .recvOnly:
                try setDirection(.sendRecv)
            default:
                return
            }
        } else {
            switch direction {
            case .sendOnly:
                try setDirection(.inactive)
            case .sendRecv:
                try setDirection(.recvOnly)
            default:
                return
            }
        }
    }

    func receive(_ enabled: Bool) throws {
        if enabled {
            switch direction {
            case .inactive:
                try setDirection(.recvOnly)
            case .sendOnly:
                try setDirection(.sendRecv)
            default:
                return
            }
        } else {
            switch direction {
            case .recvOnly:
                try setDirection(.inactive)
            case .sendRecv:
                try setDirection(.sendOnly)
            default:
                return
            }
        }
    }

    func setDegradationPreference(_ preference: DegradationPreference) {
        let parameters = sender.parameters
        let rtcPreference: RTCDegradationPreference = {
            switch preference {
            case .balanced:
                return .balanced
            case .maintainFramerate:
                return .maintainFramerate
            case .maintainResolution:
                return .maintainResolution
            case .disabled:
                return .disabled
            }
        }()
        parameters.degradationPreference = rtcPreference.rawValue as NSNumber
        sender.parameters = parameters
    }
}
