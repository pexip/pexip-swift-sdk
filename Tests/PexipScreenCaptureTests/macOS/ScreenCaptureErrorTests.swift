#if os(macOS)

import XCTest
@testable import PexipScreenCapture

final class ScreenCaptureErrorTests: XCTestCase {
    func testDescription() {
        let errors: [ScreenCaptureError] = [
            .noScreenMediaSourceAvailable,
            .cgError(.failure)
        ]

        for error in errors {
            XCTAssertEqual(error.description, error.errorDescription)
        }
    }
}

#endif
