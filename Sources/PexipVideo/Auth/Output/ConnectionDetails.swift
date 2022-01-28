import Foundation

struct ConnectionDetails: Decodable, Hashable {
    enum ServiceType: String, Decodable, Hashable {
        case conference
        case gateway
        case testCall = "test_call"
    }
    
    private enum CodingKeys: String, CodingKey {
        case participantUUID = "participant_uuid"
        case serviceType = "service_type"
    }

    /// The uuid associated with this newly created participant.
    /// It is used to identify this participant in the participant list.
    let participantUUID: UUID
    /// VMR, gateway or Test Call Service
    let serviceType: ServiceType
}
