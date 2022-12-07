import XCTest
@testable import PexipRTC

final class OptionalExtensionsTests: XCTestCase {
    func testValueOrNil() {
        XCTAssertNil((nil as String?).valueOrNil(String.self))
        XCTAssertEqual(("Test" as String?).valueOrNil(String.self), "Test")
    }
}
