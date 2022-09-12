import Foundation

/// The registration token response.
public struct RegistrationToken: InfinityToken, Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case value = "token"
        case registrationId = "registration_uuid"
        case directoryEnabled = "directory_enabled"
        case routeViaRegistrar = "route_via_registrar"
        case version
        case expiresString = "expires"
    }

    /// A textual representation of this type, suitable for debugging.
    public static let name = "Registration token"

    /// The authentication token for future requests.
    public private(set) var value: String

    /// Date when the token was requested
    public private(set) var updatedAt = Date()

    /// The registration id.
    public let registrationId: UUID

    /// The directory enabled flag.
    public let directoryEnabled: Bool

    /// The route via registrar flag.
    public let routeViaRegistrar: Bool

    /// The version of the Pexip server being communicated with.
    public let version: Version

    /// Validity lifetime in seconds.
    public var expires: TimeInterval {
        TimeInterval(expiresString) ?? 0
    }

    private var expiresString: String

    // MARK: - Init

    public init(
        value: String,
        updatedAt: Date = Date(),
        registrationId: UUID,
        directoryEnabled: Bool,
        routeViaRegistrar: Bool,
        expiresString: String,
        version: Version
    ) {
        self.value = value
        self.updatedAt = updatedAt
        self.registrationId = registrationId
        self.directoryEnabled = directoryEnabled
        self.routeViaRegistrar = routeViaRegistrar
        self.expiresString = expiresString
        self.version = version
    }

    // MARK: - Update

    public func updating(
        value: String,
        expires: String,
        updatedAt: Date = .init()
    ) -> RegistrationToken {
        var token = self
        token.value = value
        token.expiresString = expires
        token.updatedAt = updatedAt
        return token
    }
}
