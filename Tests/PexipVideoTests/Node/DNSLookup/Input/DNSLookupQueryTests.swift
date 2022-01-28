import XCTest
import dnssd
@testable import PexipVideo

final class DNSLookupQueryTests: XCTestCase {
    func testInit() throws {
        let query = DNSLookupQuery(
            domain: "example.org",
            serviceType: kDNSServiceType_A,
            handler: { _, _, _, _, _, _, _, _, _, _, _ in }
        )
        
        XCTAssertEqual(query.domain, "example.org")
        XCTAssertEqual(query.serviceType, kDNSServiceType_A)
    }
}
