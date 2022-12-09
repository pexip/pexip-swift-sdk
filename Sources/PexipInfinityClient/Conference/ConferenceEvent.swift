import Foundation

/// Conference-related events.
@frozen
public enum ConferenceEvent: Hashable {
    /// New conference splash screen event received.
    case splashScreen(SplashScreenEvent?)

    /// Conference properties have been updated.
    case conferenceUpdate(ConferenceStatus)

    /// New live captions event received.
    case liveCaptions(LiveCaptions)

    /// A chat message has been broadcast to the conference.
    case messageReceived(ChatMessage)

    /// New SDP offer received
    case newOffer(NewOfferMessage)

    /// Remote SDP updated
    case updateSdp(UpdateSdpMessage)

    /// New ICE candidate received
    case newCandidate(IceCandidate)

    /// Marks the start of a presentation,
    /// and includes the information on which participant is presenting.
    case presentationStart(PresentationStartEvent)

    /// The presentation has finished.
    case presentationStop

    /// Sending of the complete participant list started.
    case participantSyncBegin

    /// Sending of the complete participant list ended.
    case participantSyncEnd

    /// A new participant has joined the conference.
    case participantCreate(Participant)

    /// A participant's properties have changed.
    case participantUpdate(Participant)

    /// A participant has left the conference.
    case participantDelete(ParticipantDeleteEvent)

    case peerDisconnected

    /// Sent when a child call has been disconnected.
    case callDisconnected(CallDisconnectEvent)

    /// Sent when the participant is being disconnected from the Pexip side.
    case clientDisconnected(ClientDisconnectEvent)

    /// Unhandled error occured during the conference call.
    case failure(FailureEvent)

    enum Name: String {
        case splashScreen = "splash_screen"
        case conferenceUpdate = "conference_update"
        case liveCaptions = "live_captions"
        case messageReceived = "message_received"
        case newOffer = "new_offer"
        case updateSdp = "update_sdp"
        case newCandidate = "new_candidate"
        case presentationStart = "presentation_start"
        case presentationStop = "presentation_stop"
        case participantSyncBegin = "participant_sync_begin"
        case participantSyncEnd = "participant_sync_end"
        case participantCreate = "participant_create"
        case participantUpdate = "participant_update"
        case participantDelete = "participant_delete"
        case peerDisconnected = "peer_disconnect"
        case callDisconnected = "call_disconnected"
        case clientDisconnected = "disconnect"
    }
}

// MARK: - Events

/// An event that includes information to be displayed to the user.
public struct SplashScreenEvent: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case key = "screen_key"
    }

    /// The key to find the corresponding splash screen theme.
    public let key: String

    /// Optional splash screen object.
    public internal(set) var splashScreen: SplashScreen?

    /// A date when the event was received.
    public private(set) var receivedAt = Date()
}

/// The status of the conference.
public struct ConferenceStatus: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case started
        case locked
        case allMuted = "all_muted"
        case guestsMuted = "guests_muted"
        case presentationAllowed = "presentation_allowed"
        case directMedia = "direct_media"
        case liveCaptionsAvailable = "live_captions_available"
    }

    /// Boolean indicating whether the conference has been started.
    public let started: Bool

    /// The lock status of the conference.
    public let locked: Bool

    /// Boolean indicating whether all the conference participants are muted.
    public let allMuted: Bool

    /// Boolean indicating whether guests are muted.
    public let guestsMuted: Bool

    /// Boolean indicating whether presentation is allowed in the coference.
    public let presentationAllowed: Bool

    /// Boolean indicating whether direct media is enabled.
    public let directMedia: Bool

    /// Live captions availability status.
    public let liveCaptionsAvailable: Bool

    /// A date when the event was received.
    public private(set) var receivedAt = Date()

    /// Creates a new instance of ``ConferenceStatus``
    ///
    /// - Parameters:
    ///   - started: Boolean indicating whether the conference has been started
    ///   - locked: The lock status of the conference
    ///   - allMuted: Boolean indicating whether all the conference participants are muted
    ///   - guestsMuted: Boolean indicating whether guests are muted
    ///   - presentationAllowed: Boolean indicating whether presentation is allowed in the coference
    ///   - directMedia: Boolean indicating whether direct media is enabled
    ///   - liveCaptionsAvailable: Live captions availability status
    ///   - receivedAt: A date when the event was received
    public init(
        started: Bool,
        locked: Bool,
        allMuted: Bool,
        guestsMuted: Bool,
        presentationAllowed: Bool,
        directMedia: Bool,
        liveCaptionsAvailable: Bool,
        receivedAt: Date = Date()
    ) {
        self.started = started
        self.locked = locked
        self.allMuted = allMuted
        self.guestsMuted = guestsMuted
        self.presentationAllowed = presentationAllowed
        self.directMedia = directMedia
        self.liveCaptionsAvailable = liveCaptionsAvailable
        self.receivedAt = receivedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        started = try container.decodeIfPresent(Bool.self, forKey: .started) ?? false
        locked = try container.decodeIfPresent(Bool.self, forKey: .locked) ?? false
        allMuted = try container.decodeIfPresent(Bool.self, forKey: .allMuted) ?? false
        guestsMuted = try container.decodeIfPresent(Bool.self, forKey: .guestsMuted) ?? false
        presentationAllowed = try container.decodeIfPresent(
            Bool.self,
            forKey: .presentationAllowed
        ) ?? false
        directMedia = try container.decodeIfPresent(Bool.self, forKey: .directMedia) ?? false
        liveCaptionsAvailable = try container.decodeIfPresent(
            Bool.self,
            forKey: .liveCaptionsAvailable
        ) ?? false
    }
}

/// An event that includes the information on which participant is presenting.
public struct PresentationStartEvent: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case presenterName = "presenter_name"
        case presenterUri = "presenter_uri"
    }

    /// The name of the presenter.
    public let presenterName: String

    /// The URI of the presenter.
    public let presenterUri: String

    /// A date when the event was received.
    public private(set) var receivedAt = Date()

    /// Creates a new instance of ``PresentationStartEvent``
    ///
    /// - Parameters:
    ///   - presenterName: The name of the presenter
    ///   - presenterUri: The URI of the presenter
    ///   - receivedAt: A date when the event was received
    public init(presenterName: String, presenterUri: String, receivedAt: Date = Date()) {
        self.presenterName = presenterName
        self.presenterUri = presenterUri
        self.receivedAt = receivedAt
    }
}

/// An event that includes the reason for the call disconnection.
public struct CallDisconnectEvent: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case callId = "call_uuid"
        case reason
    }

    /// The UUID of the call.
    public let callId: UUID

    /// The reason for the disconnection.
    public let reason: String

    /// A when the event was received.
    public private(set) var receivedAt = Date()

    /// Creates a new instance of ``CallDisconnectEvent``
    ///
    /// - Parameters:
    ///   - callId: The UUID of the call
    ///   - reason: The reason for the disconnection
    ///   - receivedAt: A date when the event was received
    public init(callId: UUID, reason: String, receivedAt: Date = Date()) {
        self.callId = callId
        self.reason = reason
        self.receivedAt = receivedAt
    }
}

/// An event that includes the reason for the participant disconnection.
public struct ClientDisconnectEvent: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case reason
    }

    /// The reason for the disconnection.
    public let reason: String

    /// A date when the event was received.
    public private(set) var receivedAt = Date()

    /// Creates a new instance of ``ClientDisconnectEvent``
    ///
    /// - Parameters:
    ///   - reason: The reason for the disconnection
    ///   - receivedAt: A date when the event was received
    public init(reason: String, receivedAt: Date = Date()) {
        self.reason = reason
        self.receivedAt = receivedAt
    }
}

/// An event to be sent when participant has left the conference.
public struct ParticipantDeleteEvent: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case id = "uuid"
    }

    /// The UUID of this participant.
    public let id: UUID

    /// A date when the event was received.
    public private(set) var receivedAt = Date()

    /// Creates a new instance of ``ParticipantDeleteEvent``
    ///
    /// - Parameters:
    ///   - id: The UUID of this participant
    ///   - receivedAt: A date when the event was received
    public init(id: UUID, receivedAt: Date = Date()) {
        self.id = id
        self.receivedAt = receivedAt
    }
}

/// A chat message that has been sent to the conference.
public struct ChatMessage: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case senderName = "origin"
        case senderId = "uuid"
        case type
        case payload
    }

    /// Name of the sending participant.
    public let senderName: String

    /// UUID of the sending participant.
    public let senderId: UUID

    /// MIME content-type of the message, usually text/plain.
    public let type: String

    /// Message contents.
    public let payload: String

    /// A date when the event was received.
    public private(set) var receivedAt = Date()

    /**
     - Parameters:
        - senderName: Name of the sending participant
        - senderId: UUID of the sending participant
        - type: MIME content-type of the message, usually text/plain
        - payload: Message contents
        - receivedAt: A date when the event was received
     */
    public init(
        senderName: String,
        senderId: UUID,
        type: String = "text/plain",
        payload: String,
        receivedAt: Date = .init()
    ) {
        self.senderName = senderName
        self.senderId = senderId
        self.type = type
        self.payload = payload
        self.receivedAt = receivedAt
    }
}

public struct NewOfferMessage: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case sdp
    }

    /// The remote offer sdp.
    public let sdp: String
    /// A date when the event was received.
    public private(set) var receivedAt = Date()

    /// Creates a new instance of ``NewOfferMessage``
    ///
    /// - Parameters:
    ///   - sdp: The remote offer sdp
    ///   - receivedAt: A date when the event was received
    public init(sdp: String, receivedAt: Date = Date()) {
        self.sdp = sdp
        self.receivedAt = receivedAt
    }
}

public typealias UpdateSdpMessage = NewOfferMessage

/// Live caption event details.
public struct LiveCaptions: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case data
        case isFinal = "is_final"
        case sentAt = "sent_time"
    }

    public let data: String
    public let isFinal: Bool
    public let sentAt: TimeInterval?

    public init(
        data: String,
        isFinal: Bool,
        sentAt: TimeInterval?
    ) {
        self.data = data
        self.isFinal = isFinal
        self.sentAt = sentAt
    }
}
