import Foundation

/// A service that helps to discover DNS SRV and A records for a specific domain.
public final class DNSLookupService {
    public var timeout: __darwin_time_t
    private let client: DNSClient
    
    // MARK: - Init
    
    public init(timeout: __darwin_time_t = 5) {
        self.timeout = timeout
        self.client = DNSServiceDiscoveryClient()
    }
    
    init(client: DNSClient, timeout: __darwin_time_t = 5) {
        self.timeout = timeout
        self.client = client
    }
    
    // MARK: - Lookup
    
    public func resolveSRVRecords(
        service: String,
        proto: String,
        name: String
    ) async throws -> [SRVRecord] {
        let name = "_\(service)._\(proto).\(name)"
        let records: [SRVRecord] = try await resolveRecords(for: name)
        
        // RFC 2782: if there is precisely one SRV RR, and its Target is "."
        // (the root domain), abort."
        if records.first?.target == ".", records.count == 1 {
            return []
        } else {
            return records.sorted()
        }
    }
    
    public func resolveARecords(for name: String) async throws -> [ARecord] {
        try await resolveRecords(for: name)
    }
    
    private func resolveRecords<T: DNSRecord>(for name: String) async throws -> [T] {
        let task = Task { () -> [T] in
            let records = try client.resolveRecords(
                forName: name,
                serviceType: T.serviceType,
                timeout: timeout
            )
            return try records.compactMap(T.init)
        }
        return try await task.value
    }
}
