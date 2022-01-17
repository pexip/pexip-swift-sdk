import XCTest
import dnssd
@testable import DNSLookup

final class ARecordTests: XCTestCase {
    func testServiceType() {
        XCTAssertEqual(ARecord.serviceType, kDNSServiceType_A)
    }
    
    func testInit() throws {
        XCTAssertEqual(
            try ARecord(data: ARecord.Stub.default.data),
            ARecord.Stub.default.instance
        )
    }
    
    func testInitWithInvalidData() throws {
        for count in 1...3 {
            let bytes = [UInt8](repeating: 100, count: count)
            XCTAssertThrowsError(try ARecord(data: Data(bytes))) { error in
                XCTAssertTrue(error is ARecordError)
            }
        }
        
        XCTAssertThrowsError(try ARecord(data: "invalid data string".data(using: .utf8)!)) { error in
            XCTAssertTrue(error is ARecordError)
        }
    }
}

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
