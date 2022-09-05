import XCTest
@testable import PexipInfinityClient

final class HTTPErrorTests: XCTestCase {
    func testDescription() {
        let errors: [HTTPError] = [
            .invalidHTTPResponse,
            .noDataInResponse,
            .unacceptableStatusCode(401),
            .unacceptableContentType("text/html; charset=UTF-8"),
            .unacceptableContentType(nil),
            .unauthorized,
            .resourceNotFound("Conference")
        ]

        for error in errors {
            XCTAssertEqual(error.description, error.errorDescription)
        }
    }
}
