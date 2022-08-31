import XCTest
@testable import PexipCore

final class RegexTests: XCTestCase {
    func testMatchEntire() {
        XCTAssertEqual(Regex("^a$").match("a")?.groupValue(at: 0), "a")
        XCTAssertNil(Regex("^a$").match("a")?.groupValue(at: 1))
        XCTAssertNil(Regex("^a$").match("ba")?.groupValue(at: 0))

        let id = UUID().uuidString
        let string = "line1\r\nkey=id:\(id)\r\nline3"

        XCTAssertEqual(
            Regex(".*\\bkey=id:(.*)").match(string)?.groupValue(at: 1),
            id
        )
    }
}
