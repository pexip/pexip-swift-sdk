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
    }

    private let dnsLookupClient: DNSLookupClientProtocol
    private let statusClient: NodeStatusClientProtocol
    private let logger: CategoryLogger

    // MARK: - Init

    init(
        dnsLookupClient: DNSLookupClientProtocol,
        statusClient: NodeStatusClientProtocol,
        logger: CategoryLogger
    ) {
        self.dnsLookupClient = dnsLookupClient
        self.statusClient = statusClient
        self.logger = logger
    }

    // MARK: - Lookup

    func resolveNodeAddress(for host: String) async throws -> URL {
        var result: URL?

        if let address = try await resolveSRVRecord(for: host) {
            result = address
        } else if let address = try await resolveARecord(for: host) {
            result = address
        }

        if let result = result {
            logger.info(
                "Found a conferencing node with address: \(result.absoluteString)"
            )
            return result
        } else {
            logger.error("No SRV or A records were found for \(host)")
            throw NodeError.nodeNotFound
        }
    }

    private func resolveSRVRecord(for host: String) async throws -> URL? {
        let name = "_\(Constants.service)._\(Constants.proto).\(host)"

        logger.debug(
            """
            Performing a look up for \(name) to see if there are any
            SRV records available for \(host)
            """
        )

        let addresses = try await dnsLookupClient
            .resolveSRVRecords(for: name)
            .compactMap(\.nodeAddress)
        return try await firstActiveAddress(from: addresses)
    }

    private func resolveARecord(for host: String) async throws -> URL? {
        logger.debug(
            "Checking if there are any A records available for \(host)"
        )

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
    var nodeAddress: URL? {
        var components = URLComponents()
        components.scheme = port == 443 ? "https" : "http"
        components.host = target
        components.port = Int(port)
        return components.url
    }
}

private extension ARecord {
    var nodeAddress: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = ipv4Address
        return components.url
    }
}
