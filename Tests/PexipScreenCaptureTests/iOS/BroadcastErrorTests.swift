#if os(iOS)

import XCTest
@testable import PexipScreenCapture

final class BroadcastErrorTests: XCTestCase {
    func testDescription() {
        let errors: [BroadcastError] = [
            .noConnection,
            .callEnded,
            .presentationStolen,
            .broadcastFinished
        ]

        for error in errors {
            XCTAssertEqual(error.description, error.errorDescription)
            XCTAssertEqual(
                error.errorUserInfo[NSLocalizedDescriptionKey] as? String,
                error.errorDescription
            )
        }
    }
}

#endif
