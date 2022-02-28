import XCTest
import dnssd
@testable import PexipVideo

final class SRVRecordTests: XCTestCase {
    func testServiceType() {
        XCTAssertEqual(SRVRecord.serviceType, kDNSServiceType_SRV)
    }

    func testInit() throws {
        let record = SRVRecord.Stub.default
        XCTAssertEqual(try SRVRecord(data: record.data), record.instance)
    }

    func testInitWithInvalidData() throws {
        for count in 1...6 {
            let bytes = [UInt8](repeating: 100, count: count)
            XCTAssertThrowsError(try SRVRecord(data: Data(bytes))) { error in
                XCTAssertTrue(error is SRVRecordError)
            }
        }
    }

    func testSorting() {
        let recordA = SRVRecord(priority: 2, weight: 10, port: 1720, target: "px01.vc.example.com")
        let recordB = SRVRecord(priority: 1, weight: 10, port: 1720, target: "px02.vc.example.com")
        let recordC = SRVRecord(priority: 2, weight: 20, port: 1720, target: "px03.vc.example.com")

        let records = [
            recordA,
            recordB,
            recordC
        ]

        XCTAssertEqual(records.sorted(), [recordB, recordC, recordA])
    }
}

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
