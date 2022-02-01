import Foundation

struct AuthForbiddenError: LocalizedError, Decodable, Hashable {
    /// PIN requirement status
    enum PinStatus: Hashable {
        /// No PIN required
        case `none`
        /// PIN is required
        case `required`
        // If a PIN is required for a Host, but not for a Guest,
        // and if you want to join as a Guest,
        // you must still provide a "pin" header, with a value of "none".
        case `optional`
    }
    
    /// Pexip Virtual Reception options
    enum ConferenceExtension: String, Decodable, Hashable {
        /// For a regular, Microsoft Teams or Google Meet Virtual Reception
        case standard
        /// for a Lync / Skype for Business Virtual Reception.
        case mssip
    }
    
    private enum CodingKeys: String, CodingKey {
        case guestPin = "guest_pin"
        case hostPin = "pin"
        case conferenceExtension = "conference_extension"
    }
    
    private enum StatusValue: String, Decodable {
        case `none`
        case `required`
    }
    
    /// Whether the conference is PIN-protected or not for Guests and Hosts
    let pinStatus: PinStatus
    /// Present only if this is a call to a Pexip Virtual Reception,
    /// where a target extension needs to be specified in the call to `connect`
    let conferenceExtension: ConferenceExtension?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let guestPin = try container.decodeIfPresent(StatusValue.self, forKey: .guestPin) ?? .none
        let hostPin = try container.decodeIfPresent(StatusValue.self, forKey: .hostPin) ?? .none
        
        conferenceExtension = try container.decodeIfPresent(
            ConferenceExtension.self,
            forKey: .conferenceExtension
        )
        
        switch (guestPin, hostPin) {
        case (.none, .none):
            self.pinStatus = .none
        case (.none, .required):
            self.pinStatus = .optional
        case (.required, _):
            self.pinStatus = .required
        }
    }
}
