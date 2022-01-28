import Foundation

/// Discovers the Pexip service via DNS SRV
final class NodeResolver {
    private enum Constants {
        static let service = "pexapp"
        static let proto = "tcp"
        static let scheme = "https"
    }
    
    private let dnsLookupClient: DNSLookupClientProtocol
    private let statusClient: NodeStatusClientProtocol
    
    // MARK: - Init
    
    init(
        dnsLookupClient: DNSLookupClientProtocol,
        statusClient: NodeStatusClientProtocol
    ) {
        self.dnsLookupClient = dnsLookupClient
        self.statusClient = statusClient
    }
    
    // MARK: - Lookup
    
    /// - Parameter uri: Conference URI in the form of conference@domain.org
    /// - Returns: The address of a Conferencing Node
    func resolveNodeAddress(for uri: ConferenceURI) async throws -> URL {
        let srvRecords = try await dnsLookupClient.resolveSRVRecords(
            service: Constants.service,
            proto: Constants.proto,
            name: uri.domain
        ).map({ try makeURL(from: $0.target) })
        
        let url: URL
        
        // Check if there are any SRV records available
        if let srvRecordURL = try await srvRecords.asyncFirst(where: {
            // Select the first Conferencing Node which is not in maintenance mode
            try await !statusClient.isInMaintenanceMode(apiURL: $0)
        }) {
            url = srvRecordURL
        } else {
            // If there are none, use the domains A record entry
            let aRecords = try await dnsLookupClient
                .resolveARecords(for: uri.domain)
                .map({ try makeURL(from: $0.ipv4Address) })
            
            if let aRecordURL = try await aRecords.asyncFirst(where: {
                // Select the first Conferencing Node which is not in maintenance mode
                try await !statusClient.isInMaintenanceMode(apiURL: $0)
            }) {
                url = aRecordURL
            } else {
                // Return passed domain if no SRV or A records found
                url = try makeURL(from: uri.domain)
            }
        }
                
        return url
    }
    
    private func makeURL(from string: String) throws -> URL {
        let string = "\(Constants.scheme)://\(string)"
        let url = URL(string: string)
        return try url.orThrow(NodeError.invalidNodeURL(string))
    }
}
