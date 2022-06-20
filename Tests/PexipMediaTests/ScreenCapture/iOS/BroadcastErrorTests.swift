#if os(iOS)

import XCTest
@testable import PexipMedia

final class BroadcastErrorTests: XCTestCase {
    func testDescription() {
        let errors: [BroadcastError] = [
            .invalidHeader,
            .broadcastFinished(error: URLError(.badURL))
        ]

        for error in errors {
            XCTAssertEqual(error.description, error.errorDescription)
        }
    }

    func testErrorUserInfo() {
        let errors: [BroadcastError] = [
            .invalidHeader,
            .broadcastFinished(error: URLError(.badURL))
        ]

        for error in errors {
            XCTAssertEqual(
                error.errorUserInfo[NSLocalizedDescriptionKey] as? String,
                error.description
            )
            switch error {
            case .invalidHeader:
                XCTAssertNil(error.errorUserInfo[NSUnderlyingErrorKey])
            case .broadcastFinished:
                XCTAssertEqual(
                    (error.errorUserInfo[NSUnderlyingErrorKey] as? URLError)?.code,
                    .badURL
                )
            }
        }
    }
}

#endif
