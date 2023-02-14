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

@frozen
public enum ConferenceSignalingError: LocalizedError, CustomStringConvertible, Hashable {
    case pwdsMissing
    case ufragMissing
    case callNotStarted

    public var description: String {
        switch self {
        case .pwdsMissing:
            return "There are no ICE pwds in the given SDP offer."
        case .ufragMissing:
            return "Ufrag is missing in the given ICE candidate."
        case .callNotStarted:
            return "The operation cannot be performed before starting a call"
        }
    }

    public var errorDescription: String? {
        description
    }
}
