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
        - nodeAddress: The address of a Conferencing Node in the form
        - alias: An alias of the conference you are connecting to
     */
    public func tokenRequester(
        nodeAddress: URL,
        alias: ConferenceAlias
    ) -> TokenRequesterProtocol {
        InfinityClient(
            nodeAddress: nodeAddress,
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
        nodeAddress: URL,
        alias: ConferenceAlias,
        token: Token,
        callConfiguration: CallConfiguration = .init()
    ) -> ConferenceProtocol {
        let tokenStorage = TokenStorage(token: token)
        let apiClient = InfinityClient(
            nodeAddress: nodeAddress,
            alias: alias,
            urlSession: urlSession,
            tokenProvider: tokenStorage,
            logger: logger
        )
        let mediaConnection = WebRTCConnection(
            iceServers: token.iceServers.isEmpty
                ? callConfiguration.backupIceServers
                : token.iceServers,
            qualityProfile: callConfiguration.qualityProfile,
            supportsAudio: callConfiguration.supportsAudio,
            supportsVideo: callConfiguration.supportsVideo,
            logger: logger
        )
        return Conference(
            conferenceName: token.conferenceName,
            userDisplayName: token.displayName,
            tokenSession: TokenSession(
                client: apiClient,
                storage: tokenStorage,
                logger: logger
            ),
            callSession: CallSession(
                participantId: token.participantId,
                qualityProfile: callConfiguration.qualityProfile,
                mediaConnection: mediaConnection,
                apiClient: apiClient,
                logger: logger
            ),
            eventSource: ServerSentEventSource(
                client: apiClient,
                logger: logger
            ),
            logger: logger
        )
    }
}
