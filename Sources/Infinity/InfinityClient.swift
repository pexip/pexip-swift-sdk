import Foundation
import DNSLookup

public actor InfinityClient {
    private let configuration: APIConfiguration
    private let clientControl: ClientControlAPI
    private var token: Token?
    
    // MARK: - Init
    
    /// - Parameter url: Conference URI in the form of conference@domain.org
    public static func client(withURI uri: String) async throws -> InfinityClient {
        try await client(withURI: uri, dnsLookupService: DNSLookupService())
    }
    
    static func client(
        withURI uri: String,
        dnsLookupService: DNSLookupService
    ) async throws -> InfinityClient {
        guard let uri = ConferenceURI(rawValue: uri) else {
            throw InfinityClientError.invalidConferenceURI(uri)
        }
        
        let nodeResolver = NodeResolver(dnsLookupService: dnsLookupService)
        
        guard let nodeAddress = try await nodeResolver.resolveNodeURL(for: uri.rawValue) else {
            throw InfinityClientError.nodeNotFound
        }
        
        let configuration = APIConfiguration(uri: uri, nodeAddress: nodeAddress)
        return InfinityClient(configuration: configuration)
    }
    
    init(configuration: APIConfiguration) {
        self.configuration = configuration
        self.clientControl = ClientControlAPI(configuration: configuration)
    }
    
    // MARK: - API
    
    func connect(
        displayName: String,
        pin: String? = nil,
        conferenceExtension: String? = nil
    ) async throws {
        token = try await clientControl.requestToken(
            displayName: displayName,
            pin: pin,
            conferenceExtension: conferenceExtension
        )
    }
}

// MARK: - Errors

enum InfinityClientError: LocalizedError {
    case invalidConferenceURI(String)
    case nodeNotFound
}
