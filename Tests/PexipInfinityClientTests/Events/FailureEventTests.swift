import XCTest
@testable import PexipInfinityClient

final class FailureEventTests: XCTestCase {
    func testInit() {
        let id = UUID()
        let receivedAt = Date()
        let error = URLError(.badURL)
        let event = FailureEvent(
            id: id,
            receivedAt: receivedAt,
            error: error
        )

        XCTAssertEqual(event.id, id)
        XCTAssertEqual(event.receivedAt, receivedAt)
        XCTAssertEqual(event.error as? URLError, error)
    }

    func testHashable() {
        let id = UUID()
        let receivedAt = Date()
        let error = URLError(.badURL)
        let event = FailureEvent(
            id: id,
            receivedAt: receivedAt,
            error: error
        )

        var hasher = Hasher()
        hasher.combine(id)
        hasher.combine(receivedAt)
        hasher.combine(error.localizedDescription)
        let hashValue = hasher.finalize()

        XCTAssertEqual(event.hashValue, hashValue)
    }

    func testEquatable() {
        let id = UUID()
        let receivedAt = Date()
        let error = URLError(.badURL)

        XCTAssertEqual(
            FailureEvent(
                id: id,
                receivedAt: receivedAt,
                error: error
            ),
            FailureEvent(
                id: id,
                receivedAt: receivedAt,
                error: error
            )
        )

        XCTAssertNotEqual(
            FailureEvent(
                id: id,
                receivedAt: receivedAt,
                error: error
            ),
            FailureEvent(
                id: id,
                receivedAt: receivedAt,
                error: URLError(.unknown)
            )
        )
    }
}
