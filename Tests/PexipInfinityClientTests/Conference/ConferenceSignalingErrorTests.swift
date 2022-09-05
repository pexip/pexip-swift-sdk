import XCTest
@testable import PexipInfinityClient

final class ConferenceSignalingErrorTests: XCTestCase {
    func testDescription() {
        let errors: [ConferenceSignalingError] = [
            .pwdsMissing,
            .ufragMissing,
            .callNotStarted
        ]

        for error in errors {
            XCTAssertEqual(error.description, error.errorDescription)
        }
    }
}
