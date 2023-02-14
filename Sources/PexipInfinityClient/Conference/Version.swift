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

public struct Version: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case versionId = "version_id"
        case pseudoVersion = "pseudo_version"
    }

    public let versionId: String
    public let pseudoVersion: String

    // MARK: - Init

    public init(versionId: String, pseudoVersion: String) {
        self.versionId = versionId
        self.pseudoVersion = pseudoVersion
    }
}
