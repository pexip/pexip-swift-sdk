import Foundation
@testable import PexipInfinityClient

extension Participant {
    static func avatarURL(id: UUID) -> URL? {
        URL(string: "https://vc.example.com/api/participant/\(id)/avatar.jpg")
    }

    static func stub(
        withId id: UUID,
        displayName: String,
        isPresenting: Bool = false
    ) -> Participant {
        Participant(
            id: id,
            displayName: displayName,
            role: .guest,
            serviceType: .conference,
            callDirection: .inbound,
            hasMedia: true,
            isExternal: false,
            isStreamingConference: false,
            isVideoMuted: false,
            canReceivePresentation: true,
            isConnectionEncrypted: true,
            isDisconnectSupported: true,
            isFeccSupported: false,
            isAudioOnlyCall: false,
            isAudioMuted: false,
            isPresenting: isPresenting,
            isVideoCall: true,
            isMuteSupported: true,
            isTransferSupported: true
        )
    }
}
