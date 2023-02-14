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

public struct Regex {
    public let pattern: String

    public init(_ pattern: String) {
        self.pattern = pattern
    }

    public func match(_ string: String) -> Match? {
        let range = NSRange(location: 0, length: string.utf16.count)
        let regex = try? NSRegularExpression(
            pattern: pattern,
            options: .caseInsensitive
        )
        let result = regex?.firstMatch(in: string, options: [], range: range)
        return result.map { Match(string: string, result: $0) }
    }
}

// MARK: - Match

public extension Regex {
    struct Match {
        fileprivate let string: String
        fileprivate let result: NSTextCheckingResult

        public func groupValue(at index: Int) -> String? {
            guard index >= 0 && index < result.numberOfRanges else {
                return nil
            }
            guard let range = Range(result.range(at: index), in: string) else {
                return nil
            }
            return String(string[range])
        }
    }
}
