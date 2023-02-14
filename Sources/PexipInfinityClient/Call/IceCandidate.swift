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

public struct IceCandidate: Hashable, Codable {
    /// Representation of address in candidate-attribute format as per RFC5245.
    public let candidate: String
    /// The media stream identifier tag.
    public let mid: String?
    /// The randomly generated username fragment of the ICE credentials.
    public let ufrag: String?
    /// The randomly generated password of the ICE credentials.
    public let pwd: String?

    // MARK: - Init

    public init(candidate: String, mid: String?, ufrag: String?, pwd: String?) {
        self.candidate = candidate
        self.mid = mid
        self.ufrag = ufrag
        self.pwd = pwd
    }
}
