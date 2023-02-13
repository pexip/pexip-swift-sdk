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

public struct CallDetails: Decodable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case id = "call_uuid"
        case sdp
    }

    public let id: String
    public let sdp: String?

    public init(id: String, sdp: String?) {
        self.id = id
        self.sdp = sdp
    }
}
