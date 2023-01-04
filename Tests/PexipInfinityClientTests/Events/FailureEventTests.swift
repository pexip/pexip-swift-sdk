import XCTest
@testable import PexipInfinityClient

final class FailureEventTests: XCTestCase {
    func testInit() {
        let id = UUID()
        let error = URLError(.badURL)
        let event = FailureEvent(
            id: id,
            error: error
        )

        XCTAssertEqual(event.id, id)
        XCTAssertEqual(event.error as? URLError, error)
    }

    func testHashable() {
        let id = UUID()
        let error = URLError(.badURL)
        let event = FailureEvent(
            id: id,
            error: error
        )

        var hasher = Hasher()
        hasher.combine(id)
        hasher.combine(error.localizedDescription)
        let hashValue = hasher.finalize()

        XCTAssertEqual(event.hashValue, hashValue)
    }

    func testEquatable() {
        let id = UUID()
        let error = URLError(.badURL)

        XCTAssertEqual(
            FailureEvent(
                id: id,
                error: error
            ),
            FailureEvent(
                id: id,
                error: error
            )
        )

        XCTAssertNotEqual(
            FailureEvent(
                id: id,
                error: error
            ),
            FailureEvent(
                id: id,
                error: URLError(.unknown)
            )
        )
    }
}
