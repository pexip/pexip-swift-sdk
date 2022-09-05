import XCTest
@testable import PexipInfinityClient

final class HTTPEventErrorTests: XCTestCase {
    private let urlError = URLError(.unknown)
    private let response = HTTPURLResponse(
        url: URL(string: "https://example.com")!,
        statusCode: 401, httpVersion: "HTTP/1.1",
        headerFields: [:]
    )!

    // MARK: - Tests

    func testInit() {
        let error = HTTPEventError(response: response, dataStreamError: urlError)

        XCTAssertEqual(error.response, response)
        XCTAssertEqual(error.dataStreamError as? URLError, urlError)
    }

    func testDescription() {
        let errors = [
            HTTPEventError(response: nil, dataStreamError: urlError),
            HTTPEventError(response: response, dataStreamError: nil),
            HTTPEventError(response: nil, dataStreamError: nil)
        ]

        for error in errors {
            XCTAssertEqual(error.description, error.errorDescription)
        }

        XCTAssertTrue(errors[0].description.contains("\(urlError.localizedDescription)"))
        XCTAssertTrue(errors[1].description.contains("\(response.statusCode)"))
        XCTAssertFalse(errors[2].description.isEmpty)
    }
}
