import Foundation

/// An event to be sent when participant has left the conference.
public struct ParticipantDeleteEvent: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case id = "uuid"
    }

    /// The UUID of this participant.
    public let id: String

    /// Creates a new instance of ``ParticipantDeleteEvent``
    ///
    /// - Parameters:
    ///   - id: The UUID of this participant
    public init(id: String) {
        self.id = id
    }
}
