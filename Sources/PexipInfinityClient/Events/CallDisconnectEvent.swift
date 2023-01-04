import Foundation

/// An event that includes the reason for the call disconnection.
public struct CallDisconnectEvent: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case callId = "call_uuid"
        case reason
    }

    /// The UUID of the call.
    public let callId: String

    /// The reason for the disconnection.
    public let reason: String

    /// Creates a new instance of ``CallDisconnectEvent``
    ///
    /// - Parameters:
    ///   - callId: The UUID of the call
    ///   - reason: The reason for the disconnection
    public init(callId: String, reason: String) {
        self.callId = callId
        self.reason = reason
    }
}
