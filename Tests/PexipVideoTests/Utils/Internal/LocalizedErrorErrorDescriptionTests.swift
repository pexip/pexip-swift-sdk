import XCTest
@testable import PexipVideo

final class LocalizedErrorErrorDescriptionTests: XCTestCase {
    func testErrorDescription() {
        let error = HTTPError.noDataInResponse

        XCTAssertEqual(
            error.errorDescription,
            error.description
        )
    }
}
