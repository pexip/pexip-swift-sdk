import Foundation
import dnssd

/// A Service record (SRV record) is a specification of data in the Domain Name System
/// defining the location, i.e., the hostname and port number, of servers for specified services.
/// https://en.wikipedia.org/wiki/SRV_record
public struct SRVRecord: Hashable, Comparable {
    /// The priority of the target host, lower value means more preferred.
    public let priority: UInt16
    /// A relative weight for records with the same priority, higher value means higher chance of getting picked.
    public let weight: UInt16
    /// The TCP or UDP port on which the service is to be found.
    public let port: UInt16
    /// The canonical hostname of the machine providing the service.
    public let target: String
    
    /// Simple sorting by priority and weight.
    /// Sorting the SRV RRs of the same priority could be improved
    /// by implementing the algorithm from RFC 2782 https://www.rfc-editor.org/rfc/rfc2782
    public static func < (lhs: SRVRecord, rhs: SRVRecord) -> Bool {
        if lhs.priority < rhs.priority {
            return true
        } else if lhs.priority == rhs.priority {
            return lhs.weight > rhs.weight
        } else {
            return false
        }
    }
}

// MARK: - DNSRecord

extension SRVRecord: DNSRecord {
    static var serviceType = kDNSServiceType_SRV

    init(data: Data) throws {
        guard data.count > 6 else {
            throw SRVRecordError()
        }
        
        priority = UInt16(bigEndian: data[0...2].withUnsafeBytes { $0.load(as: UInt16.self) })
        weight = UInt16(bigEndian: data[2...4].withUnsafeBytes { $0.load(as: UInt16.self) })
        port = UInt16(bigEndian: data[4...6].withUnsafeBytes { $0.load(as: UInt16.self) })
        
        // A byte array of format [size][ascii bytes]...[null]
        var targetData = data.subdata(in: 6..<data.endIndex)
        var index = targetData.startIndex
        
        while index < targetData.endIndex {
            let size = Int(targetData[index])
            targetData[index] = UInt8(46) // Replace with "." (period, dot)
            index = index.advanced(by: size + 1)
        }
        
        // Drop first and last dots
        targetData = targetData.dropFirst().dropLast()
        target = String(data: targetData, encoding: .ascii) ?? ""
    }
}

// MARK: - Errors

struct SRVRecordError: LocalizedError {
    let errorDescription = "Invalid SRV record data"
}

#if DEBUG

// MARK: - Stubs

extension SRVRecord {
    struct Stub {
        let instance: SRVRecord
        let data: Data
        
        // Name:        vc.example.com
        // Service:     h323cs
        // Protocol:    tcp
        // Priority:    10
        // Weight:      20
        // Port:        1720
        // Target:      px01.vc.example.com
        static let `default` = Stub(
            instance: SRVRecord(
                priority: 10,
                weight: 20,
                port: 1720,
                target: "px01.vc.example.com"
            ),
            data: Data([
                0x00, 0x0A, // Priority: 10
                0x00, 0x14, // Weight: 20
                0x06, 0xB8, // Port: 1720
                0x04, 0x70, 0x78, 0x30, 0x31, // px01 (size = 4)
                0x02, 0x76, 0x63, // vc (size = 2)
                0x07, 0x65, 0x78, 0x61, 0x6d, 0x70, 0x6c, 0x65, // example (size = 7)
                0x03, 0x63, 0x6f, 0x6d, // com (size = 3)
                0x00 // null
            ])
        )
        
        // Name:        vc.example.com
        // Service:     h323cs
        // Protocol:    tcp
        // Priority:    20
        // Weight:      20
        // Port:        1720
        // Target:      .
        static let root = Stub(
            instance: SRVRecord(
                priority: 20,
                weight: 20,
                port: 1720,
                target: "."
            ),
            data: Data([
                0x00, 0x14, // Priority: 20
                0x00, 0x14, // Weight: 20
                0x06, 0xB8, // Port: 1720
                0x01, 0x2e, // . (size 1)
                0x00 // null
            ])
        )
    }
}

#endif
