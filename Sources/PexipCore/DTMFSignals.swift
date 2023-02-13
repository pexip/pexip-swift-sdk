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

/// Representation of the DTMF signals.
public struct DTMFSignals: RawRepresentable, Hashable {
    public static let allowedCharacters = CharacterSet(charactersIn: "0123456789*#ABCD")
    public var rawValue: String

    /**
     Creates a new instance of ``DTMFSignals`` struct.

     - Parameters:
        - rawValue: The DTMF string.
     */
    public init?(rawValue: String) {
        let rawValue = rawValue.trimmingCharacters(in: .whitespaces)

        guard !rawValue.isEmpty else {
            return nil
        }

        guard CharacterSet(
            charactersIn: rawValue
        ).isSubset(of: Self.allowedCharacters) else {
            return nil
        }

        self.rawValue = rawValue
    }
}
