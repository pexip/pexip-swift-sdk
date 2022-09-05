import XCTest
@testable import PexipInfinityClient

final class DNSLookupErrorTests: XCTestCase {
    func testDescription() {
        let errors: [DNSLookupError] = [
            .timeout,
            .lookupFailed(code: 1000),
            .responseNotSecuredWithDNSSEC,
            .invalidSRVRecordData,
            .invalidARecordData
        ]

        for error in errors {
            XCTAssertEqual(error.description, error.errorDescription)
        }
    }
}
