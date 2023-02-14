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

/// SSO identity provider
public struct IdentityProvider: Hashable, Decodable {
    private enum CodingKeys: String, CodingKey {
        case name
        case id = "uuid"
    }

    /// The name of the identity provider
    public let name: String
    /// The uuid corresponds to the UUID of the configuration on Infinity
    public let id: String

    // MARK: - Init

    public init(name: String, id: String) {
        self.name = name
        self.id = id
    }
}
