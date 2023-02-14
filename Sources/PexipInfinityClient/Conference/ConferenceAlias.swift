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

/// An alias of the conference you are connecting to.
public struct ConferenceAlias: Hashable {
    public let uri: String
    public let alias: String
    public let host: String

    // MARK: - Init

    /// - Parameter uri: Conference URI in the form of conference@example.com
    public init?(uri: String) {
        let parts = uri.components(separatedBy: "@")

        guard let alias = parts.first, let host = parts.last, parts.count == 2 else {
            return nil
        }

        self.init(alias: alias, host: host)
    }

    /**
     - Parameters:
        - alias: Conference or device alias
        - host: Conference host in the form of "example.com"
     */
    public init?(alias: String, host: String) {
        let uri = "\(alias)@\(host)"
        let checkingType = NSTextCheckingResult.CheckingType.link.rawValue
        let detector = try? NSDataDetector(types: checkingType)
        let range = NSRange(uri.startIndex..<uri.endIndex, in: uri)
        let matches = detector?.matches(in: uri, options: [], range: range)

        // Check if our string contains only a single email
        guard let match = matches?.first, matches?.count == 1 else {
            return nil
        }

        guard match.url?.scheme == "mailto", match.range == range else {
            return nil
        }

        self.uri = uri
        self.alias = alias
        self.host = host
    }
}
