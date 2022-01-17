import XCTest
import dnssd
@testable import DNSLookup

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
