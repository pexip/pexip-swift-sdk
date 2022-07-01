import Foundation
import PexipMedia
import PexipInfinityClient
import PexipUtils

/// ``ConferenceFactory`` provides factory methods to create conference objects.
public struct ConferenceFactory {
    private let logger: Logger?

    // MARK: - Init

    /**
     Creates a new instance of ``ConferenceFactory``
     - Parameters:
        - logger: An optional object for writing messages to the logging system of choice
     */
    public init(logger: Logger? = DefaultLogger.conference) {
        self.logger = logger
    }

    // MARK: - Public methods

    /**
     Creates a new instance of ``Conference`` type.
     - Parameters:
        - service: A client for Infinity REST API v2
        - node: A conferencing node address in the form of https://example.com
        - alias: A conference alias
        - token: A token of the conference
     */
    public func conference(
        service: InfinityService,
        node: URL,
        alias: ConferenceAlias,
        token: Token
    ) -> Conference {
        let service = service.node(url: node).conference(alias: alias)
        let tokenStore = DefaultTokenStore(token: token)
        let roster = roster(token: token, service: service)

        return InfinityConference(
            conferenceName: token.conferenceName,
            tokenRefresher: DefaultTokenRefresher(
                service: service,
                store: tokenStore,
                logger: logger
            ),
            signaling: ConferenceSignaling(
                participantService: service.participant(id: token.participantId),
                tokenStore: tokenStore,
                roster: roster,
                iceServers: token.iceServers,
                logger: logger
            ),
            eventSource: DefaultEventSource(
                service: service.eventSource(),
                tokenStore: tokenStore,
                logger: logger
            ),
            chat: chat(token: token, tokenStore: tokenStore, service: service),
            roster: roster,
            logger: logger
        )
    }

    // MARK: - Private methods

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

// MARK: - Private extension

private extension Token {
    var iceServers: [IceServer] {
        let stunIceServers = (stun ?? []).map {
            IceServer(url: $0.url)
        }
        let turnIceServers = (turn ?? []).map {
            IceServer(urls: $0.urls, username: $0.username, password: $0.credential)
        }
        return stunIceServers + turnIceServers
    }
}
