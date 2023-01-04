import Foundation
@testable import PexipInfinityClient

extension ConferenceToken {
    static func randomToken(
        updatedAt: Date = .init(),
        expires: TimeInterval = 120,
        stun: [String]? = [],
        turn: [Turn]? = nil,
        role: Role = .guest,
        chatEnabled: Bool = true,
        directMedia: Bool = false,
        dataChannelId: Int32? = nil
    ) -> ConferenceToken {
        ConferenceToken(
            value: UUID().uuidString,
            updatedAt: updatedAt,
            participantId: UUID().uuidString,
            role: role,
            displayName: "Guest",
            serviceType: "conference",
            conferenceName: "Test",
            stun: stun.map { $0.map(ConferenceToken.Stun.init(url:)) },
            turn: turn,
            chatEnabled: chatEnabled,
            dataChannelId: dataChannelId,
            analyticsEnabled: Bool.random(),
            directMedia: directMedia,
            expiresString: "\(expires)",
            version: Version(versionId: "10", pseudoVersion: "25010.0.0")
        )
    }
}
