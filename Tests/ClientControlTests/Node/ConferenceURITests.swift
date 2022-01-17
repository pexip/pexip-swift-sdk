import XCTest
import dnssd
@testable import ClientControl

final class ConferenceURITests: XCTestCase {
    func testInit() throws {
        XCTAssertNil(ConferenceURI(rawValue: "."))
        XCTAssertNil(ConferenceURI(rawValue:"conference"))
        XCTAssertNil(ConferenceURI(rawValue:"@domain"))
        XCTAssertNil(ConferenceURI(rawValue:"@domain.org"))
        XCTAssertNil(ConferenceURI(rawValue:"conference@domain.org conference@domain.org"))
        
        let uri = try XCTUnwrap(ConferenceURI(rawValue:"conference@domain.org"))
        XCTAssertEqual(uri.rawValue, "conference@domain.org")
        XCTAssertEqual(uri.alias, "conference")
        XCTAssertEqual(uri.host, "domain.org")
    }
}
