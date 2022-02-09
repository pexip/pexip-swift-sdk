import Foundation

struct ConnectionDetails: Decodable, Hashable {
    enum ServiceType: String, Decodable, Hashable {
        case conference
        case gateway
        case testCall = "test_call"
    }

    struct Stun: Decodable, Hashable {
        let url: String
    }

    private enum CodingKeys: String, CodingKey {
        case participantUUID = "participant_uuid"
        case displayName = "display_name"
        case serviceType = "service_type"
        case conferenceName = "conference_name"
        case stun
    }

    /// The uuid associated with this newly created participant.
    /// It is used to identify this participant in the participant list.
    let participantUUID: UUID
    /// The name by which this participant should be known
    let displayName: String
    /// VMR, gateway or Test Call Service
    let serviceType: ServiceType
    /// The name of the conference
    let conferenceName: String
    // STUN server configuration from the Pexip Conferencing Node
    let stun: [Stun]?

    var iceServers: [String] {
        (stun ?? []).map(\.url)
    }
}
