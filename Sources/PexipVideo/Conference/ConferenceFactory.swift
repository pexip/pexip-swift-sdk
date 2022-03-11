import Foundation

public struct ConferenceFactory {
    private let logger: LoggerProtocol
    private let urlSession: URLSession

    // MARK: - Init

    /**
     - Parameters:
        - logger: An optional object for writing messages to the logging system of choice
        - urlSession: An optional instance of `URLSession` to make HTTP calls
     */
    public init(
        logger: LoggerProtocol = SilentLogger(),
        urlSession: URLSession = .init(configuration: .ephemeral)
    ) {
        self.logger = logger
        self.urlSession = urlSession
    }

    // MARK: - Factory

    /**
     - Parameter dnssec: Sets whether DNSSEC should be used to resolve node address
     */
    public func nodeResolver(dnssec: Bool = false) -> NodeResolverProtocol {
        NodeResolver(
            dnsLookupClient: DNSLookupClient(),
            statusClient: NodeStatusClient(
                urlSession: urlSession,
                logger: logger[.http]
            ),
            dnssec: dnssec,
            logger: logger[.dnsLookup]
        )
    }

    /**
     - Parameters:
        - node: A Conferencing node
        - alias: An alias of the conference you are connecting to
     */
    public func tokenRequester(
        node: Node,
        alias: ConferenceAlias
    ) -> TokenRequesterProtocol {
        InfinityClient(
            node: node,
            alias: alias,
            urlSession: urlSession,
            tokenProvider: nil,
            logger: logger
        )
    }

    /**
     - Parameters:
        - nodeAddress: The address of a Conferencing Node in the form
        - alias: An alias of the conference you are connecting to
        - token: A valid unexpired API token requested by `TokenRequesterProtocol`
     */
    public func conference(
        node: Node,
        alias: ConferenceAlias,
        token: Token,
        callConfiguration: CallConfiguration = .init()
    ) -> ConferenceProtocol {
        let tokenStorage = TokenStorage(token: token)
        let apiClient = InfinityClient(
            node: node,
            alias: alias,
            urlSession: urlSession,
            tokenProvider: tokenStorage,
            logger: logger
        )
        var chat: Chat?

        if token.chatEnabled {
            chat = Chat(
                senderName: token.displayName,
                senderId: token.participantId,
                sendMessage: { text in
                    try await apiClient.sendChatMessage(text)
                }
            )
        }

        return Conference(
            conferenceName: token.conferenceName,
            userDisplayName: token.displayName,
            tokenSession: TokenSession(
                client: apiClient,
                storage: tokenStorage,
                logger: logger
            ),
            callSessionFactory: CallSessionFactory(
                participantId: token.participantId,
                iceServers: iceServers(
                    fromToken: token,
                    callConfiguration: callConfiguration
                ),
                qualityProfile: callConfiguration.qualityProfile,
                callMediaFeatures: callConfiguration.mediaFeatures,
                apiClient: apiClient,
                logger: logger
            ),
            serverEventSession: ServerEventSession(
                client: apiClient,
                logger: logger
            ),
            chat: chat,
            logger: logger
        )
    }

    // MARK: - Internal

    func iceServers(
        fromToken token: Token,
        callConfiguration: CallConfiguration
    ) -> [String] {
        token.iceServers.isEmpty
            ? callConfiguration.backupIceServers
            : token.iceServers
    }
}
