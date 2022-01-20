import Foundation

struct Token: Decodable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case authToken = "token"
        case expiresString = "expires"
        case participantUUID = "participant_uuid"
        case role
        case serviceType = "service_type"
    }
    
    enum Role: String, Decodable, Hashable {
        case host = "HOST"
        case guest = "GUEST"
    }
    
    enum ServiceType: String, Decodable, Hashable {
        case conference
        case gateway
        case testCall = "test_call"
    }

    /// The authentication token for future requests.
    let authToken: String
    /// Validity lifetime in seconds.
    var expires: TimeInterval? { TimeInterval(expiresString) }
    /// The uuid associated with this newly created participant.
    /// It is used to identify this participant in the participant list.
    let participantUUID: UUID
    /// Whether the participant is connecting as a "HOST" or a "GUEST".
    let role: Role
    /// VMR, gateway or Test Call Service
    let serviceType: ServiceType
    
    private let expiresString: String
}
