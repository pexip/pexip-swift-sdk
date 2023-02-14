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

public struct NewOfferMessage: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case sdp
    }

    /// The remote offer sdp.
    public let sdp: String

    /// Creates a new instance of ``NewOfferMessage``
    ///
    /// - Parameters:
    ///   - sdp: The remote offer sdp
    public init(sdp: String) {
        self.sdp = sdp
    }
}

public typealias UpdateSdpMessage = NewOfferMessage
