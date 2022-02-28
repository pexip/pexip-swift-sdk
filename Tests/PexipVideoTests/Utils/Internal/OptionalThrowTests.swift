import XCTest
@testable import PexipVideo

final class OptionalThrowTests: XCTestCase {
    func testOrThrow() throws {
        var data: Data?
        XCTAssertThrowsError(try data.orThrow(HTTPError.noDataInResponse)) { error in
            XCTAssertEqual(error as? HTTPError, .noDataInResponse)
        }

        data = Data()
        XCTAssertNoThrow(try data.orThrow(HTTPError.noDataInResponse))
    }
}
