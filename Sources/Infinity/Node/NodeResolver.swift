import Foundation
import DNSLookup

final class NodeResolver {
    private enum Constants {
        static let service = "pexapp"
        static let proto = "tcp"
        static let scheme = "https"
    }
    
    private let dnsLookupService: DNSLookupService
    
    // MARK: - Init
    
    init(dnsLookupService: DNSLookupService) {
        self.dnsLookupService = dnsLookupService
    }
    
    // MARK: - Lookup
    
    /// - Parameter url: Conference URI in the form of conference@domain.org
    /// - Returns: Node URL
    func resolveNodeURL(for uri: String) async throws -> URL? {
        guard let uri = ConferenceURI(rawValue: uri) else {
            throw NodeResolverError()
        }

        let srvRecords = try await dnsLookupService.resolveSRVRecords(
            service: Constants.service,
            proto: Constants.proto,
            name: uri.host
        )
        
        if let srvRecord = srvRecords.first {
            // Check if there are any SRV records available
            return makeURL(from: srvRecord.target)
        } else {
            // If there are none, use the domains A record entry
            return try await dnsLookupService.resolveARecords(for: uri.host)
                .first
                .flatMap { makeURL(from: $0.ipv4Address) }
        }
    }
    
    private func makeURL(from string: String) -> URL? {
        URL(string: "\(Constants.scheme)://\(string)")
    }
}

// MARK: - Errors

struct NodeResolverError: LocalizedError {
    let errorDescription = "Invalid conference URI, must be in the form of conference@domain.org"
}
