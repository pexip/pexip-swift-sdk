import Foundation
import PexipCore

// MARK: - Protocol

/// Discovers the Pexip service via DNS SRV
public protocol NodeResolver {
    /**
     Resolves the node addresses for the provided `host`.
     Clients should consult with
     [documentation](https://docs.pexip.com/clients/configuring_dns_pexip_app.htm#next_gen_mobile)
     for the recommended flow.

     - Parameter host: A host to use to resolve the best node address
     - Returns: A list of node addresses in the form of https://example.com
     - Throws: `DNSError` if DNS lookup failed
     - Throws: `Error` if a network error was encountered
     */
    func resolveNodes(for host: String) async throws -> [URL]
}

// MARK: - Implementation

struct DefaultNodeResolver: NodeResolver {
    fileprivate enum Constants {
        static let service = "pexapp"
        static let proto = "tcp"
    }

    let dnsLookupClient: DNSLookupClientProtocol
    let dnssec: Bool
    var logger: Logger?

    // MARK: - Lookup

    func resolveNodes(for host: String) async throws -> [URL] {
        var nodes = try await resolveSRVRecords(for: host)

        if nodes.isEmpty {
            nodes = try await resolveARecords(for: host)
        }

        if nodes.isEmpty {
            logger?.warn("No SRV or A records were found for \(host)")
        } else {
            logger?.info(
                "Found \(nodes.count) conferencing nodes for \(host)"
            )
        }

        return nodes
    }

    private func resolveSRVRecords(for host: String) async throws -> [URL] {
        let name = "_\(Constants.service)._\(Constants.proto).\(host)"

        logger?.debug(
            "Performing a look up for \(name) to see if there are any " +
            "SRV records available for \(host)"
        )

        do {
            return try await dnsLookupClient
                .resolveSRVRecords(for: name, dnssec: dnssec)
                .compactMap(\.nodeAddress)
        } catch {
            logger?.error("SRV lookup error: \(error)")
            return []
        }
    }

    private func resolveARecords(for host: String) async throws -> [URL] {
        logger?.debug(
            "Checking if there are any A records available for \(host)"
        )
        return try await dnsLookupClient
            .resolveARecords(for: host, dnssec: dnssec)
            .compactMap(\.nodeAddress)
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
