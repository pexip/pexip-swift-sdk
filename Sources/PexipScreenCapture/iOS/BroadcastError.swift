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

#if os(iOS)

import Foundation

/// An object that represents the error occured during IPC.
@frozen
public enum BroadcastError: LocalizedError, CustomStringConvertible, CustomNSError {
    public static let errorDomain = "com.pexip.PexipScreenCapture.BroadcastError"

    case noConnection
    case callEnded
    case presentationStolen
    case broadcastFinished

    public var description: String {
        switch self {
        case .noConnection:
            return "No connection to the main app. Most likely you're not in a call."
        case .callEnded:
            return "Call ended."
        case .presentationStolen:
            return "Presentation has been stolen by another participant."
        case .broadcastFinished:
            return "Screen broadcast finished."
        }
    }

    public var errorDescription: String? {
        description
    }

    public var errorUserInfo: [String: Any] {
        return [NSLocalizedDescriptionKey: description]
    }
}

#endif
