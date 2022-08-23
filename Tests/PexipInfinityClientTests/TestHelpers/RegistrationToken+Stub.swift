import Foundation
@testable import PexipInfinityClient

extension RegistrationToken {
    static func randomToken(
        updatedAt: Date = .init(),
        expires: TimeInterval = 120
    ) -> RegistrationToken {
        RegistrationToken(
            value: UUID().uuidString,
            updatedAt: updatedAt,
            registrationId: UUID(),
            directoryEnabled: Bool.random(),
            routeViaRegistrar: Bool.random(),
            expiresString: "\(expires)",
            version: Version(versionId: "10", pseudoVersion: "25010.0.0")
        )
    }
}
