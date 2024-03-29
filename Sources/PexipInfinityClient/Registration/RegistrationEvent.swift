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

import Foundation

/// Registration-related events.
@frozen
public enum RegistrationEvent: Hashable {
    /// An event to be sent when there is a new icoming call.
    case incoming(IncomingCallEvent)

    /// An event to be sent when the incoming call was cancelled.
    case incomingCancelled(IncomingCallCancelledEvent)

    /// Unhandled error occured during the registration operations.
    case failure(FailureEvent)

    enum Name: String {
        case incoming = "incoming"
        case incomingCancelled = "incoming_cancelled"
    }
}

// MARK: - Events

/// An event to be sent when there is a new icoming call.
public struct IncomingCallEvent: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case conferenceAlias = "conference_alias"
        case remoteDisplayName = "remote_display_name"
        case token
    }

    /// An alias of the conference.
    public let conferenceAlias: String

    /// The display name of the caller.
    public let remoteDisplayName: String

    /// The incoming registration token.
    public let token: String

    /// Creates a new instance of ``IncomingCallEvent``
    ///
    /// - Parameters:
    ///   - conferenceAlias: An alias of the conference
    ///   - remoteDisplayName: The display name of the caller
    ///   - token: The incoming registration token
    public init(
        conferenceAlias: String,
        remoteDisplayName: String,
        token: String
    ) {
        self.conferenceAlias = conferenceAlias
        self.remoteDisplayName = remoteDisplayName
        self.token = token
    }
}

/// An event to be sent when the incoming call was cancelled.
public struct IncomingCallCancelledEvent: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case token
    }

    /// The incoming registration token.
    public let token: String

    /// Creates a new instance of ``IncomingCallCancelledEvent``
    ///
    /// - Parameters:
    ///   - token: The incoming registration token
    public init(token: String) {
        self.token = token
    }
}
