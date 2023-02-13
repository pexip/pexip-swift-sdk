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

import Foundation

/// An event that includes the reason for the call disconnection.
public struct CallDisconnectEvent: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case callId = "call_uuid"
        case reason
    }

    /// The UUID of the call.
    public let callId: String

    /// The reason for the disconnection.
    public let reason: String

    /// Creates a new instance of ``CallDisconnectEvent``
    ///
    /// - Parameters:
    ///   - callId: The UUID of the call
    ///   - reason: The reason for the disconnection
    public init(callId: String, reason: String) {
        self.callId = callId
        self.reason = reason
    }
}
