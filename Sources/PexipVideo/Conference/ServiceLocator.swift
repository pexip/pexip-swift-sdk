import Foundation

struct ServiceLocator {
    let logger: LoggerProtocol
    let apiConfiguration: APIConfiguration
    let authStorage = AuthStorage()
    var urlProtocolClasses = [AnyClass]()

    static func makeNodeResolver(logger: LoggerProtocol) -> NodeResolverProtocol {
        NodeResolver(
            dnsLookupClient: DNSLookupClient(),
            statusClient: NodeStatusClient(httpSession: HTTPSession(logger: logger[.http])),
            logger: logger[.dnsLookup]
        )
    }

    func makeAuthSession() -> AuthSession {
        return AuthSession(
            client: AuthClient(
                apiConfiguration: apiConfiguration,
                httpSession: makeHTTPSession(),
                authStorage: authStorage
            ),
            storage: authStorage,
            logger: logger[.auth]
        )
    }

    func makeEventSourceClient() -> SSEClientProtocol {
        SSEClient(
            apiConfiguration: apiConfiguration,
            authStorage: authStorage,
            logger: logger[.sse],
            urlProtocolClasses: urlProtocolClasses
        )
    }

    private func makeHTTPSession() -> HTTPSession {
        HTTPSession(protocolClasses: urlProtocolClasses, logger: logger[.http])
    }
}
