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

import AVFoundation

@frozen
public enum MediaCapturePermissionError: LocalizedError,
                                         CustomStringConvertible,
                                         CaseIterable {
    case restricted
    case denied

    public var description: String {
        switch self {
        case .restricted:
            return "The user can't grant access due to restrictions"
        case .denied:
            return "The user has previously denied access"
        }
    }

    public var errorDescription: String? {
        description
    }

    public init?(status: AVAuthorizationStatus) {
        switch status {
        case .notDetermined, .authorized:
            return nil
        case .restricted:
            self = .restricted
        case .denied:
            self = .denied
        @unknown default:
            return nil
        }
    }
}
