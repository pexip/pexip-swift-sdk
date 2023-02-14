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

enum IceConnectionState: String, CustomStringConvertible, CaseIterable {
    case new
    case checking
    case connected
    case completed
    case failed
    case disconnected
    case closed
    case count
    case unknown

    init(_ value: RTCIceConnectionState) {
        switch value {
        case .new:
            self = .new
        case .checking:
            self = .checking
        case .connected:
            self = .connected
        case .completed:
            self = .completed
        case .failed:
            self = .failed
        case .disconnected:
            self = .disconnected
        case .closed:
            self = .closed
        case .count:
            self = .count
        @unknown default:
            self = .unknown
        }
    }

    var description: String {
        rawValue.capitalized
    }
}
