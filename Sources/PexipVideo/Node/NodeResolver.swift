import Foundation

// MARK: - Protocol

/// Discovers the Pexip service via DNS SRV
public protocol NodeResolverProtocol {
    /**
     Resolves the node address for the provided `host`.

     - Parameter host: A host to use to resolve the best node address
     - Returns: A node address in the form of https://example.com or null if node was not found
     - Throws: `DNSError` if DNS lookup failed
     - Throws: `Error` if a network error was encountered
     */
    func resolveNode(for host: String) async throws -> Node?
}

// MARK: - Implementation

struct NodeResolver: NodeResolverProtocol {
    fileprivate enum Constants {
        static let service = "pexapp"
        static let proto = "tcp"
    }

    private let dnsLookupClient: DNSLookupClientProtocol
    private let statusClient: NodeStatusClientProtocol
    private let dnssec: Bool
    private let logger: CategoryLogger

    // MARK: - Init

    init(
        dnsLookupClient: DNSLookupClientProtocol,
        statusClient: NodeStatusClientProtocol,
        dnssec: Bool,
        logger: CategoryLogger
    ) {
        self.dnsLookupClient = dnsLookupClient
        self.statusClient = statusClient
        self.dnssec = dnssec
        self.logger = logger
    }

    // MARK: - Lookup

    func resolveNode(for host: String) async throws -> Node? {
        var url: URL?

        if let address = try await resolveSRVRecord(for: host) {
            url = address
        } else if let address = try await resolveARecord(for: host) {
            url = address
        }

        if let url = url {
            logger.info(
                "Found a conferencing node with address: \(url.absoluteString)"
            )
        } else {
            logger.warn("No SRV or A records were found for \(host)")
        }

        return url.map(Node.init(address:))
    }

    private func resolveSRVRecord(for host: String) async throws -> URL? {
        let name = "_\(Constants.service)._\(Constants.proto).\(host)"

        logger.debug(
            """
            Performing a look up for \(name) to see if there are any
            SRV records available for \(host)
            """
        )

        do {
            let addresses = try await dnsLookupClient
                .resolveSRVRecords(for: name, dnssec: dnssec)
                .compactMap(\.nodeAddress)
            return try await firstActiveAddress(from: addresses)
        } catch {
            logger.error("SRV lookup error: \(error)")
            return nil
        }
    }

    private func resolveARecord(for host: String) async throws -> URL? {
        logger.debug(
            "Checking if there are any A records available for \(host)"
        )

        let addresses = try await dnsLookupClient
            .resolveARecords(for: host, dnssec: dnssec)
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
