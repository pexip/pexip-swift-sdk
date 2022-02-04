import Foundation

// MARK: - Protocol

/// Discovers the Pexip service via DNS SRV
protocol NodeResolverProtocol {
    /// Resolves the node address for the provided [host]. Implementations should consult with
    /// (documentation)[https://docs.pexip.com/clients/configuring_dns_pexip_app.htm#next_gen_mobile]
    /// for the recommended flow.
    ///
    /// - Parameter host: A host to use to resolve the best node address (e.g. example.com)
    /// - Returns: A node address in the form of https://example.com
    /// - Throws: `NodeError.nodeNotFound` if the node address cannot be resolved
    /// - Throws: `Error` if an error was encountered during operation
    func resolveNodeAddress(for host: String) async throws -> URL
}

// MARK: - Implementation

struct NodeResolver: NodeResolverProtocol {
    fileprivate enum Constants {
        static let service = "pexapp"
        static let proto = "tcp"
        static let httpScheme = "http"
        static let httpPort: UInt16 = 80
        static let httpsScheme = "https"
        static let httpsPort: UInt16 = 443
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

    func resolveNodeAddress(for host: String) async throws -> URL {
        if let address = try await resolveSRVRecord(for: host) {
            return address
        } else if let address = try await resolveARecord(for: host) {
            return address
        } else {
            throw NodeError.nodeNotFound
        }
    }

    private func resolveSRVRecord(for host: String) async throws -> URL? {
        let addresses = try await dnsLookupClient.resolveSRVRecords(
            service: Constants.service,
            proto: Constants.proto,
            name: host
        ).compactMap(\.nodeAddress)
        return try await firstActiveAddress(from: addresses)
    }

    private func resolveARecord(for host: String) async throws -> URL? {
        let addresses = try await dnsLookupClient
            .resolveARecords(for: host)
            .compactMap(\.nodeAddress)
        return try await firstActiveAddress(from: addresses)
    }

    private func firstActiveAddress(from addresses: [URL]) async throws -> URL? {
        try await addresses.asyncFirst(where: {
            // Select the first Conferencing Node which is not in maintenance mode
            try await !statusClient.isInMaintenanceMode(nodeAddress: $0)
        })
    }
}

// MARK: - Private extensions

private extension SRVRecord {
    private typealias Constants = NodeResolver.Constants

    var nodeAddress: URL? {
        let scheme = self.port == Constants.httpsPort
            ? Constants.httpsScheme
            : Constants.httpScheme
        let port = [Constants.httpPort, Constants.httpsPort].contains(self.port)
            ? ""
            : ":\(self.port)"
        return URL(string: "\(scheme)://\(target)\(port)")
    }
}

private extension ARecord {
    private typealias Constants = NodeResolver.Constants

    var nodeAddress: URL? {
        URL(string: "\(Constants.httpsScheme)://\(ipv4Address)")
    }
}
