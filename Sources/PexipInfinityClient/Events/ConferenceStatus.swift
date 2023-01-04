import Foundation

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
    public init(
        started: Bool,
        locked: Bool,
        allMuted: Bool,
        guestsMuted: Bool,
        presentationAllowed: Bool,
        directMedia: Bool,
        liveCaptionsAvailable: Bool
    ) {
        self.started = started
        self.locked = locked
        self.allMuted = allMuted
        self.guestsMuted = guestsMuted
        self.presentationAllowed = presentationAllowed
        self.directMedia = directMedia
        self.liveCaptionsAvailable = liveCaptionsAvailable
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
