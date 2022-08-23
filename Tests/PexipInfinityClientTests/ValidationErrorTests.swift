import XCTest
@testable import PexipInfinityClient

final class ValidationErrorTests: XCTestCase {
    func testDescription() {
        let errors: [ValidationError] = [
            .invalidArgument
        ]

        for error in errors {
            XCTAssertEqual(error.description, error.errorDescription)
        }
    }
}
