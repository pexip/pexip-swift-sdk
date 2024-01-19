//
// Copyright 2023-2024 Pexip AS
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

import Combine
import WebRTC
import PexipMedia

final class Transceiver {
    var receiverId: String { transceiver.receiver.receiverId }
    private(set) var mid: String?

    private var transceiver: RTCRtpTransceiver
    private var senderTrack: WebRTCLocalTrack?
    private var senderCancellable: AnyCancellable?

    // MARK: - Init

    init(_ transceiver: RTCRtpTransceiver) {
        self.transceiver = transceiver
    }

    deinit {
        transceiver.stopInternal()
    }

    // MARK: - Internal

    var canReceive: Bool {
        transceiver.direction == .recvOnly || transceiver.direction == .sendRecv
    }

    var canSend: Bool {
        transceiver.direction == .sendOnly || transceiver.direction == .sendRecv
    }

    func setDirection(_ direction: RTCRtpTransceiverDirection) throws {
        guard transceiver.direction != direction else {
            return
        }

        var error: NSError?
        transceiver.setDirection(direction, error: &error)

        if let error {
            throw error
        }
    }

    func syncMid() {
        mid = transceiver.mid
    }

    func sync(with newTransceiver: RTCRtpTransceiver?) throws {
        guard let newTransceiver, newTransceiver != transceiver else {
            return
        }

        let oldTransceiver = transceiver
        transceiver = newTransceiver

        try setDirection(oldTransceiver.direction)
        transceiver.sender.track = oldTransceiver.sender.track

        if oldTransceiver.mid.isEmpty {
            oldTransceiver.stopInternal()
        }
    }

    func send(
        from track: WebRTCLocalTrack?,
        onCapture: @escaping (Bool) -> Void
    ) throws {
        try send(track != nil)
        transceiver.sender.track = track?.streamMediaTrack
        senderCancellable = track?.capturingStatus
            .$isCapturing.sink { isCapturing in
                onCapture(isCapturing)
            }
        if track == nil {
            onCapture(false)
        }
        senderTrack = track
    }

    func send(_ enabled: Bool) throws {
        if enabled {
            switch transceiver.direction {
            case .inactive:
                try setDirection(.sendOnly)
            case .recvOnly:
                try setDirection(.sendRecv)
            default:
                return
            }
        } else {
            switch transceiver.direction {
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
            switch transceiver.direction {
            case .inactive:
                try setDirection(.recvOnly)
            case .sendOnly:
                try setDirection(.sendRecv)
            default:
                return
            }
        } else {
            switch transceiver.direction {
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
        let parameters = transceiver.sender.parameters
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
        transceiver.sender.parameters = parameters
    }
}
