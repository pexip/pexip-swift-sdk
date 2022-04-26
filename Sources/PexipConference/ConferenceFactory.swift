import Foundation
import PexipMedia
import PexipInfinityClient
import PexipUtils

public struct ConferenceFactory {
    private let logger: Logger?

    // MARK: - Init

    public init(logger: Logger? = DefaultLogger.conference) {
        self.logger = logger
    }

    // MARK: - Public methods

    public func conference(
        service: InfinityService,
        node: URL,
        alias: ConferenceAlias,
        token: Token
    ) -> Conference {
        let service = service.node(url: node).conference(alias: alias)
        let tokenStore = DefaultTokenStore(token: token)
        func signaling() -> MediaConnectionSignaling {
            self.signaling(token: token, tokenStore: tokenStore, service: service)
        }

        return InfinityConference(
            conferenceName: token.conferenceName,
            tokenRefresher: DefaultTokenRefresher(
                service: service,
                store: tokenStore,
                logger: logger
            ),
            mainSignaling: signaling(),
            presentationSignaling: signaling(),
            eventSource: DefaultEventSource(
                service: service.eventSource(),
                tokenStore: tokenStore,
                logger: logger
            ),
            chat: chat(token: token, tokenStore: tokenStore, service: service),
            roster: roster(token: token, service: service),
            logger: logger
        )
    }

    // MARK: - Private methods

    private func signaling(
        token: Token,
        tokenStore: TokenStore,
        service: ConferenceService
    ) -> MediaConnectionSignaling {
        ConferenceSignaling(
            participantService: service.participant(id: token.participantId),
            tokenStore: tokenStore,
            logger: logger
        )
    }

    private func chat(
        token: Token,
        tokenStore: TokenStore,
        service: ConferenceService
    ) -> Chat? {
        guard token.chatEnabled else {
            return nil
        }

        return Chat(
            senderName: token.displayName,
            senderId: token.participantId,
            sendMessage: { text in
                try await service.message(text, token: tokenStore.token())
            }
        )
    }

    private func roster(
        token: Token,
        service: ConferenceService
    ) -> Roster {
        Roster(
            currentParticipantId: token.participantId,
            currentParticipantName: token.displayName,
            avatarURL: { id in
                service.participant(id: token.participantId).avatarURL()
            }
        )
    }
}
