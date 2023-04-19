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

// swiftlint:disable identifier_name
public struct Participant: Codable, Hashable, Identifiable {
    public init(
        id: String,
        displayName: String,
        localAlias: String = "",
        overlayText: String = "",
        role: Participant.Role,
        serviceType: Participant.ServiceType,
        buzzTime: TimeInterval = 0,
        callDirection: Participant.CallDirection,
        callTag: String? = nil,
        externalNodeId: String? = nil,
        callProtocol: String? = nil,
        spotlightTime: TimeInterval = 0,
        startTime: TimeInterval? = nil,
        uri: String? = nil,
        vendor: String? = nil,
        hasMedia: Bool,
        isExternal: Bool,
        isStreamingConference: Bool,
        isVideoMuted: Bool,
        canReceivePresentation: Bool,
        isConnectionEncrypted: Bool,
        isDisconnectSupported: Bool,
        isFeccSupported: Bool,
        isAudioOnlyCall: Bool,
        isAudioMuted: Bool,
        isPresenting: Bool,
        isVideoCall: Bool,
        isMuteSupported: Bool,
        isTransferSupported: Bool
    ) {
        self.id = id
        self.displayName = displayName
        self.localAlias = localAlias
        self.overlayText = overlayText
        self.role = role
        self.serviceType = serviceType
        self.buzzTime = buzzTime
        self.callDirection = callDirection
        self.callTag = callTag
        self.externalNodeId = externalNodeId
        self.callProtocol = callProtocol
        self.spotlightTime = spotlightTime
        self.startTime = startTime
        self.uri = uri
        self.vendor = vendor
        self.hasMedia = hasMedia
        self.isExternal = isExternal
        self.isStreamingConference = isStreamingConference
        self.isVideoMuted = isVideoMuted
        self._canReceivePresentation = canReceivePresentation ? .allow : .deny
        self._isConnectionEncrypted = isConnectionEncrypted ? .on : .off
        self._isDisconnectSupported = isDisconnectSupported ? .yes : .no
        self._isFeccSupported = isFeccSupported ? .yes : .no
        self._isAudioOnlyCall = isAudioOnlyCall ? .yes : .no
        self._isAudioMuted = isAudioMuted ? .yes : .no
        self._isPresenting = isPresenting ? .yes : .no
        self._isVideoCall = isVideoCall ? .yes : .no
        self._isMuteSupported = isMuteSupported ? .yes : .no
        self._isTransferSupported = isTransferSupported ? .yes : .no
    }

    /// Either "in" or "out" as to whether this is an inbound or outbound call.
    @frozen
    public enum CallDirection: String, Codable, Hashable {
        /// Inbound call
        case inbound = "in"
        /// Outbound call
        case outbound = "out"
    }

    /// The level of privileges the participant has in the conference.
    @frozen
    public enum Role: String, Codable, Hashable {
        /// The participant has Guest privileges
        case guest
        /// The participant has Host privileges
        case chair
    }

    @frozen
    public enum ServiceType: String, Codable, Hashable {
        /// For a dial-out participant that has not been answered
        case connecting = "connecting"
        /// If waiting to be allowed to join a locked conference
        case waitingRoom = "waiting_room"
        /// If on the PIN entry screen
        case ivr = "ivr"
        /// If in a VMR
        case conference = "conference"
        /// If in a Virtual Auditorium
        case lecture = "lecture"
        /// If it is a gateway call
        case gateway = "gateway"
        /// If it is a Test Call Service
        case testCall = "test_call"
    }

    /// The UUID of this participant, to use with other operations.
    public let id: String
    /// The display name of the participant.
    public let displayName: String
    /// The calling or "from" alias. This is the alias that the recipient would use to return the call.
    public let localAlias: String
    /// Text that may be used as an alternative to display_name as the participant name overlay text.
    public let overlayText: String
    /// The level of privileges the participant has in the conference.
    public let role: Role
    /// The service type.
    public let serviceType: ServiceType
    /// A Unix timestamp of when this participant raised their hand, otherwise zero
    public let buzzTime: TimeInterval
    /// Either "in" or "out" as to whether this is an inbound or outbound call.
    public let callDirection: CallDirection
    /// An optional call tag that is assigned to this participant.
    public let callTag: String?
    /// The UUID of an external node e.g. a Skype for Business / Lync meeting associated with an
    /// external participant. This allows grouping of external participants as the UUID will be
    /// the same for all participants associated with that external node.
    public let externalNodeId: String?
    /// The call protocol.
    /// Values: "api", "webrtc", "sip", "rtmp", "h323" or "mssip".
    /// (Note that the protocol is always reported as "api" when an Infinity Connect client dials in to Pexip Infinity.)
    public let callProtocol: String?
    /// A Unix timestamp of when this participant was spotlighted, if spotlight is used.
    public let spotlightTime: TimeInterval
    /// A Unix timestamp of when this participant joined (UTC).
    public let startTime: TimeInterval?
    /// The URI of the participant.
    public let uri: String?
    /// The vendor identifier of the browser/endpoint with which the participant is connecting.
    public let vendor: String?

    // MARK: - Booleans

    /// Boolean indicating whether the user has media capabilities.
    public let hasMedia: Bool
    /// Boolean indicating if it is an external participant, e.g. coming in from a Skype for Business / Lync meeting.
    public let isExternal: Bool
    /// Boolean indicating whether this is a streaming/recording participant.
    public let isStreamingConference: Bool
    /// Boolean indicating whether this participant is administratively video muted.
    public let isVideoMuted: Bool
    /// Set to "ALLOW" if the participant is administratively allowed to receive presentation, or "DENY" if disallowed.
    public var canReceivePresentation: Bool { _canReceivePresentation == .allow }
    private let _canReceivePresentation: ReceivePresentationPolicy
    /// "On" or "Off" as to whether this participant is connected via encrypted media.
    public var isConnectionEncrypted: Bool { _isConnectionEncrypted == .on }
    private let _isConnectionEncrypted: Encryption?
    /// Boolean indicating whether the participant can be disconnected.
    public var isDisconnectSupported: Bool { _isDisconnectSupported == .yes }
    private let _isDisconnectSupported: Boolean
    /// Boolean indicating whether this participant can be sent FECC messages.
    public var isFeccSupported: Bool { _isFeccSupported == .yes }
    private let _isFeccSupported: Boolean
    /// Boolean indicating whether the call is audio only.
    public var isAudioOnlyCall: Bool { _isAudioOnlyCall == .yes }
    private let _isAudioOnlyCall: Boolean
    /// Boolean indicating whether the participant is administratively audio muted.
    public var isAudioMuted: Bool { _isAudioMuted == .yes }
    private let _isAudioMuted: Boolean
    /// Boolean indicating whether the participant is the current presenter.
    public var isPresenting: Bool { _isPresenting == .yes }
    private let _isPresenting: Boolean
    /// Boolean indicating whether the call has video capability.
    public var isVideoCall: Bool { _isVideoCall == .yes }
    private let _isVideoCall: Boolean
    /// Boolean indicating whether the participant can be muted, "NO" if not.
    public var isMuteSupported: Bool { _isMuteSupported == .yes }
    private let _isMuteSupported: Boolean
    /// Boolean indicating whether this participant can be transferred into another VMR.
    public var isTransferSupported: Bool { _isTransferSupported == .yes }
    private let _isTransferSupported: Boolean

    // MARK: - Private types

    private enum CodingKeys: String, CodingKey {
        case id = "uuid"
        case displayName = "display_name"
        case localAlias = "local_alias"
        case overlayText = "overlay_text"
        case role
        case serviceType = "service_type"
        case buzzTime = "buzz_time"
        case callDirection = "call_direction"
        case callTag = "call_tag"
        case externalNodeId = "external_node_uuid"
        case hasMedia = "has_media"
        case isExternal = "is_external"
        case isStreamingConference = "is_streaming_conference"
        case isVideoMuted = "is_video_muted"
        case callProtocol = "protocol"
        case spotlightTime = "spotlight"
        case startTime = "start_time"
        case uri
        case vendor
        case _isConnectionEncrypted = "encryption"
        case _canReceivePresentation = "rx_presentation_policy"
        case _isDisconnectSupported = "disconnect_supported"
        case _isFeccSupported = "fecc_supported"
        case _isAudioOnlyCall = "is_audio_only_call"
        case _isAudioMuted = "is_muted"
        case _isPresenting = "is_presenting"
        case _isVideoCall = "is_video_call"
        case _isMuteSupported = "mute_supported"
        case _isTransferSupported = "transfer_supported"
    }

    private enum Boolean: String, Codable {
        case yes = "YES"
        case no = "NO"
    }

    private enum Encryption: String, Codable {
        case on = "On"
        case off = "Off"
        case unknown = "Unknown"
    }

    private enum ReceivePresentationPolicy: String, Codable {
        case allow = "ALLOW"
        case deny = "DENY"
    }
}
// swiftlint:enable identifier_name
