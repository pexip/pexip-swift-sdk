import Foundation
import PexipCore

public typealias IceServer = PexipCore.IceServer

public struct InfinityClientFactory {
    private let session: URLSession
    private let logger: Logger?

    /**
     Creates a new instance of ``InfinityClientFactory``

     - Parameters:
        - urlSession: An optional instance of `URLSession` to make HTTP calls
        - logger: An optional object for writing messages to the logging system of choice
     */
    public init(
        session: URLSession = .init(configuration: .ephemeral),
        logger: Logger? = DefaultLogger.infinityClient
    ) {
        self.session = session
        self.logger = logger
    }

    /**
     Creates a default implementation of ``InfinityService``

     - Returns: An instance of ``InfinityService``
     */
    public func infinityService() -> InfinityService {
        let decoder = JSONDecoder()
        let client = HTTPClient(
            session: session,
            decoder: decoder,
            logger: logger
        )
        return DefaultInfinityService(
            client: client,
            decoder: decoder,
            logger: logger
        )
    }

    /**
     Creates a default implementation of ``NodeResolver``

     - Parameters:
        - dnssec: Enable The Domain Name System Security Extensions

     - Returns: An instance of ``NodeResolver``
     */
    public func nodeResolver(dnssec: Bool) -> NodeResolver {
        DefaultNodeResolver(
            dnsLookupClient: DNSLookupClient(),
            dnssec: dnssec,
            logger: logger
        )
    }

    /**
     Creates a new instance of ``Registration`` type.

     - Parameters:
        - node: A conferencing node address in the form of https://example.com
        - deviceAlias: A device alias
        - token: A registration token

     - Returns: A new instance of ``Registration``.
     */
    public func registration(
        node: URL,
        deviceAlias: DeviceAlias,
        token: RegistrationToken
    ) -> Registration {
        let nodeService = infinityService().node(url: node)
        let registrationService = nodeService.registration(deviceAlias: deviceAlias)
        let eventService = registrationService.eventSource()
        let tokenStore = TokenStore(token: token)

        return DefaultRegistration(
            tokenRefresher: DefaultTokenRefresher(
                service: registrationService,
                store: tokenStore,
                logger: logger
            ),
            eventSource: InfinityEventSource<RegistrationEvent>(
                name: "Registration",
                logger: logger,
                stream: {
                    try await eventService.events(token: tokenStore.token())
                }
            ),
            logger: logger
        )
    }

    /**
     Creates a new instance of ``Conference`` type.

     - Parameters:
        - service: A client for Infinity REST API v2
        - node: A conferencing node address in the form of https://example.com
        - alias: A conference alias
        - token: A token of the conference

     - Returns: A new instance of ``Conference``.
     */
    public func conference(
        service: InfinityService,
        node: URL,
        alias: ConferenceAlias,
        token: ConferenceToken
    ) -> Conference {
        let conferenceService = service.node(url: node).conference(alias: alias)
        let tokenStore = TokenStore(token: token)
        let roster = roster(token: token, service: conferenceService)
        let eventService = conferenceService.eventSource()
        let participantService = conferenceService.participant(id: token.participantId)

        return DefaultConference(
            tokenStore: tokenStore,
            tokenRefresher: DefaultTokenRefresher(
                service: conferenceService,
                store: tokenStore,
                logger: logger
            ),
            signalingChannel: ConferenceSignalingChannel(
                participantService: participantService,
                tokenStore: tokenStore,
                roster: roster,
                iceServers: token.iceServers,
                logger: logger
            ),
            eventSource: InfinityEventSource<ConferenceEvent>(
                name: "Conference",
                logger: logger,
                stream: {
                    try await eventService.events(token: tokenStore.token())
                }
            ),
            roster: roster,
            liveCaptionsService: participantService,
            chat: chat(
                token: token,
                tokenStore: tokenStore,
                service: conferenceService
            ),
            logger: logger
        )
    }

    // MARK: - Private methods

    private func chat(
        token: ConferenceToken,
        tokenStore: TokenStore<ConferenceToken>,
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
        token: ConferenceToken,
        service: ConferenceService
    ) -> Roster {
        Roster(
            currentParticipantId: token.participantId,
            currentParticipantName: token.displayName,
            avatarURL: { id in
                service.participant(id: id).avatarURL()
            }
        )
    }
}

// MARK: - Private extension

private extension ConferenceToken {
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
