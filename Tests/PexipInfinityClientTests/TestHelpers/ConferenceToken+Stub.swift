import Foundation
@testable import PexipInfinityClient

extension ConferenceToken {
    static func randomToken(
        updatedAt: Date = .init(),
        expires: TimeInterval = 120,
        stun: [String] = []
    ) -> ConferenceToken {
        ConferenceToken(
            value: UUID().uuidString,
            updatedAt: updatedAt,
            participantId: UUID(),
            role: .guest,
            displayName: "Guest",
            serviceType: "conference",
            conferenceName: "Test",
            stun: stun.map(ConferenceToken.Stun.init(url:)),
            turn: nil,
            chatEnabled: true,
            analyticsEnabled: Bool.random(),
            expiresString: "\(expires)",
            version: Version(versionId: "10", pseudoVersion: "25010.0.0")
        )
    }
}
