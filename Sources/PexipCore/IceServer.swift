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

public struct IceServer: Hashable {
    public enum Kind {
        case turn
        case stun
    }

    public let kind: Kind
    public let urls: [String]
    public let username: String?
    public let password: String?

    // MARK: - Init

    public init(
        kind: Kind,
        urls: [String],
        username: String? = nil,
        password: String? = nil
    ) {
        self.kind = kind
        self.urls = urls
        self.username = username
        self.password = password
    }

    public init(
        kind: Kind,
        url: String,
        username: String? = nil,
        password: String? = nil
    ) {
        self.init(kind: kind, urls: [url], username: username, password: password)
    }
}
