import Foundation
import dnssd

/// An A record maps a domain name to the IP address (Version 4) of the computer hosting the domain
public struct ARecord: Hashable {
    /// The IPv4 address the A record points to.
    public let ipv4Address: String
}

// MARK: - DNSRecord

extension ARecord: DNSRecord {
    static var serviceType = kDNSServiceType_A
    
    init(data: Data) throws {
        guard data.count == 4 else {
            throw ARecordError()
        }
        
        ipv4Address = "\(data[0]).\(data[1]).\(data[2]).\(data[3])"
    }
}

// MARK: - Errors

struct ARecordError: LocalizedError {
    let errorDescription = "Invalid A record data"
}

#if DEBUG

// MARK: - Stubs

extension ARecord {
    struct Stub {
        let instance: ARecord
        let data: Data
    
        // Hostname:    px01.vc.example.com
        // IP address:  198.51.100.40
        static let `default` = Stub(
            instance: ARecord(ipv4Address: "198.51.100.40"),
            data: Data([198, 51, 100, 40])
        )
    }
}

#endif
