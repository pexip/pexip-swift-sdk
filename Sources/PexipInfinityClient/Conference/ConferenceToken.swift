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
import PexipCore

public struct ConferenceToken: InfinityToken, Codable, Hashable {
    @frozen
    public enum Role: String, Codable, Hashable {
        case host = "HOST"
        case guest = "GUEST"
    }

    public struct Stun: Codable, Hashable {
        public let url: String
    }

    public struct Turn: Codable, Hashable {
        public let urls: [String]
        public let username: String
        public let credential: String
    }

    // swiftlint:disable identifier_name
    private enum CodingKeys: String, CodingKey {
        case value = "token"
        case expiresString = "expires"
        case participantId = "participant_uuid"
        case role
        case displayName = "display_name"
        case serviceType = "service_type"
        case conferenceName = "conference_name"
        case stun
        case turn
        case chatEnabled = "chat_enabled"
        case dataChannelId = "pex_datachannel_id"
        case version
        case _analyticsEnabled = "analytics_enabled"
        case _directMedia = "direct_media"
    }

    /// A textual representation of this type, suitable for debugging.
    public static let name = "Conference token"

    /// The authentication token for future requests.
    public private(set) var value: String

    /// Date when the token was requested
    public private(set) var updatedAt = Date()

    /// The uuid associated with this newly created participant.
    /// It is used to identify this participant in the participant list.
    public let participantId: String

    /// Whether the participant is connecting as a "HOST" or a "GUEST".
    public let role: Role

    /// The name by which this participant should be known
    public let displayName: String

    /// VMR, gateway or Test Call Service
    public let serviceType: String?

    /// The name of the conference
    public let conferenceName: String

    // STUN server configuration from the Pexip Conferencing Node
    public let stun: [Stun]?

    // TURN server configuration from the Pexip Conferencing Node
    public let turn: [Turn]?

    /// true = chat is enabled; false = chat is not enabled
    public let chatEnabled: Bool

    /// The id of the data channel for direct media connections
    public let dataChannelId: Int32?

    /// Whether the Automatically send deployment and usage statistics
    /// to Pexip global setting has been enabled on the Pexip installation.
    public var analyticsEnabled: Bool {
        _analyticsEnabled ?? false
    }

    /// true = direct media is enabled; false = direct media is not enabled
    public var directMedia: Bool {
        _directMedia ?? false
    }

    /// The version of the Pexip server being communicated with.
    public let version: Version

    /// Validity lifetime in seconds.
    public var expires: TimeInterval {
        TimeInterval(expiresString) ?? 0
    }

    private(set) var expiresString: String
    private let _analyticsEnabled: Bool?
    private let _directMedia: Bool?

    // MARK: - Init

    public init(
        value: String,
        updatedAt: Date = Date(),
        participantId: String,
        role: ConferenceToken.Role,
        displayName: String,
        serviceType: String,
        conferenceName: String,
        stun: [ConferenceToken.Stun]?,
        turn: [ConferenceToken.Turn]?,
        chatEnabled: Bool,
        dataChannelId: Int32? = nil,
        analyticsEnabled: Bool? = nil,
        directMedia: Bool? = nil,
        expiresString: String,
        version: Version
    ) {
        self.value = value
        self.updatedAt = updatedAt
        self.participantId = participantId
        self.role = role
        self.displayName = displayName
        self.serviceType = serviceType
        self.conferenceName = conferenceName
        self.stun = stun
        self.turn = turn
        self.chatEnabled = chatEnabled
        self.expiresString = expiresString
        self.dataChannelId = dataChannelId
        self._analyticsEnabled = analyticsEnabled
        self._directMedia = directMedia
        self.version = version
    }

    // MARK: - Update

    public func updating(
        value: String,
        expires: String,
        updatedAt: Date = .init()
    ) -> ConferenceToken {
        var token = self
        token.value = value
        token.expiresString = expires
        token.updatedAt = updatedAt
        return token
    }
}

// MARK: - Ice server

public typealias IceServer = PexipCore.IceServer

public extension ConferenceToken {
    /// The list of ice servers.
    var iceServers: [IceServer] {
        let stunIceServers = (stun ?? []).map {
            IceServer(kind: .stun, url: $0.url)
        }
        let turnIceServers = (turn ?? []).map {
            IceServer(
                kind: .turn,
                urls: $0.urls,
                username: $0.username,
                password: $0.credential
            )
        }
        return stunIceServers + turnIceServers
    }
}
