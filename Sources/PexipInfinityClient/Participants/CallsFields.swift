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

import Foundation

public struct CallsFields: Encodable, Hashable {
    @frozen
    public enum Present: String, Encodable {
        case main
        case send
        case receive
    }

    private enum CodingKeys: String, CodingKey {
        case callType = "call_type"
        case sdp
        case present
    }

    /// "WEBRTC" for a WebRTC call
    public var callType: String
    /// Contains the SDP of the sender
    public var sdp: String
    /// Optional field. Contains "send" or "receive" to act as a
    /// presentation stream rather than a main audio/video stream
    public var present: Present?

    // MARK: - Init

    /**
     - Parameters:
        - callType: "WEBRTC" for a WebRTC call
        - sdp: Contains the SDP of the sender
        - present: Optional field. Contains "send" or "receive" to act as a
                   presentation stream rather than a main audio/video stream
     */
    public init(
        callType: String,
        sdp: String,
        present: Present? = nil
    ) {
        self.callType = callType
        self.sdp = sdp
        self.present = present
    }
}
