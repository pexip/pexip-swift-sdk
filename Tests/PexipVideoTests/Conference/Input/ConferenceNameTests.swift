import XCTest
import dnssd
@testable import PexipVideo

final class ConferenceNameTests: XCTestCase {
    func testInit() throws {
        XCTAssertNil(ConferenceName(rawValue: "."))
        XCTAssertNil(ConferenceName(rawValue: "conference"))
        XCTAssertNil(ConferenceName(rawValue: "@domain"))
        XCTAssertNil(ConferenceName(rawValue: "@domain.org"))
        XCTAssertNil(ConferenceName(rawValue: "conference@domain.org conference@domain.org"))

        let name = try XCTUnwrap(ConferenceName(rawValue: "conference@domain.org"))
        XCTAssertEqual(name.rawValue, "conference@domain.org")
        XCTAssertEqual(name.alias, "conference")
        XCTAssertEqual(name.domain, "domain.org")
    }
}
