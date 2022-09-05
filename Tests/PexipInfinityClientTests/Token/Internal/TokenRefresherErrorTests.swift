import XCTest
@testable import PexipInfinityClient

final class TokenRefresherErrorTests: XCTestCase {
    func testDescription() {
        let errors: [TokenRefresherError] = [
            .tokenRefreshStarted,
            .tokenRefreshEnded
        ]

        for error in errors {
            XCTAssertEqual(error.description, error.errorDescription)
        }
    }
}
