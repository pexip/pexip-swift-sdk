import Foundation
import PexipUtils

public struct InfinityClientFactory {
    private let session: URLSession
    private let logger: Logger?

    /**
     Creates a new instance of ``PexipInfinityFactory``
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

    public func nodeResolver(dnssec: Bool) -> NodeResolver {
        DefaultNodeResolver(
            dnsLookupClient: DNSLookupClient(),
            dnssec: dnssec,
            logger: logger
        )
    }
}
