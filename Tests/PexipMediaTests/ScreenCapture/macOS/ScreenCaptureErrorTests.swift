#if os(macOS)

import XCTest
@testable import PexipMedia

final class ScreenCaptureErrorTests: XCTestCase {
    func testDescription() {
        let errors: [ScreenCaptureError] = [
            .noScreenVideoSourceAvailable,
            .cgError(.failure)
        ]

        for error in errors {
            XCTAssertEqual(error.description, error.errorDescription)
        }
    }
}

#endif
