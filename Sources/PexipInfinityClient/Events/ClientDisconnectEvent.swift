import Foundation

/// An event that includes the reason for the participant disconnection.
public struct ClientDisconnectEvent: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case reason
    }

    /// The reason for the disconnection.
    public let reason: String

    /// Creates a new instance of ``ClientDisconnectEvent``
    ///
    /// - Parameters:
    ///   - reason: The reason for the disconnection
    public init(reason: String) {
        self.reason = reason
    }
}
