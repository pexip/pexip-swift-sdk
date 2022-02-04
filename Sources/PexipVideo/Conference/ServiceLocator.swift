import Foundation

struct ServiceLocator {
    let apiConfiguration: APIConfiguration
    let authStorage = AuthStorage()
    var urlProtocolClasses = [AnyClass]()

    static func makeNodeResolver() -> NodeResolverProtocol {
        NodeResolver(
            dnsLookupClient: DNSLookupClient(),
            statusClient: NodeStatusClient(urlSession: .ephemeral())
        )
    }

    func makeAuthSession() -> AuthSession {
        return AuthSession(
            client: AuthClient(
                apiConfiguration: apiConfiguration,
                urlSession: makeURLSession(),
                authStorage: authStorage
            ),
            storage: authStorage
        )
    }

    func makeEventSourceClient() -> SSEClientProtocol {
        SSEClient(
            apiConfiguration: apiConfiguration,
            authStorage: authStorage,
            urlProtocolClasses: urlProtocolClasses
        )
    }

    private func makeURLSession() -> URLSession {
        URLSession.ephemeral(protocolClasses: urlProtocolClasses)
    }
}
