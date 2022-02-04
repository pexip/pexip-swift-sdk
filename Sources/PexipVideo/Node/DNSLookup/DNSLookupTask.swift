import dnssd

// MARK: - Protocol

protocol DNSLookupTaskProtocol {
    func prepare() -> DNSServiceErrorType
    func start() async -> DNSServiceErrorType
    func cancel()
}

// MARK: - Implementation

struct DNSLookupTask: DNSLookupTaskProtocol {
    let query: DNSLookupQuery
    private let sdRef: UnsafeMutablePointer<OpaquePointer?> = .allocate(
        capacity: MemoryLayout<OpaquePointer>.size
    )

    func prepare() -> DNSServiceErrorType {
        DNSServiceQueryRecord(
            sdRef,
            0,
            0,
            query.domain,
            UInt16(query.serviceType),
            UInt16(kDNSServiceClass_IN),
            query.handler,
            &query.result
        )
    }

    func start() async -> DNSServiceErrorType {
        DNSServiceProcessResult(sdRef.pointee)
    }

    func cancel() {
        DNSServiceRefDeallocate(sdRef.pointee)
    }
}
