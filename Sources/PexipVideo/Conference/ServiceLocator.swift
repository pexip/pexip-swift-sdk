import Foundation

struct ServiceLocator {
    let apiConfiguration: APIConfiguration
    let authStorage = AuthStorage()
    var urlSession = URLSession.ephemeral()
    
    static func makeNodeResolver() -> NodeResolver {
        NodeResolver(
            dnsLookupClient: DNSLookupClient(),
            statusClient: NodeStatusClient(urlSession: .ephemeral())
        )
    }
    
    func makeAuthSession() -> AuthSession {
        return AuthSession(
            client: AuthClient(
                apiConfiguration: apiConfiguration,
                urlSession: urlSession,
                authStorage: authStorage
            ),
            storage: authStorage
        )
    }
}
