import Foundation

/// An event to be sent when the participant has been transfered to another call.
public struct ReferEvent: Codable, Hashable {
    /// The one time token.
    public let token: String

    /// An alias of the conference.
    public let alias: String

    /// Creates a new instance of ``ReferEvent``
    ///
    /// - Parameters:
    ///   - token: The one time token
    ///   - alias: An alias of the conference
    public init(token: String, alias: String) {
        self.token = token
        self.alias = alias
    }
}
