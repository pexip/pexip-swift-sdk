import XCTest
import dnssd
@testable import PexipInfinityClient

final class ConferenceAliasTests: XCTestCase {
    func testInitWithURI() throws {
        XCTAssertNil(ConferenceAlias(uri: ""))
        XCTAssertNil(ConferenceAlias(uri: "."))
        XCTAssertNil(ConferenceAlias(uri: "conference"))
        XCTAssertNil(ConferenceAlias(uri: "@example"))
        XCTAssertNil(ConferenceAlias(uri: "@example.com"))
        XCTAssertNil(ConferenceAlias(uri: "conference@example.com conference@example.com"))

        let name = try XCTUnwrap(ConferenceAlias(uri: "conference@example.com"))
        XCTAssertEqual(name.uri, "conference@example.com")
        XCTAssertEqual(name.alias, "conference")
        XCTAssertEqual(name.host, "example.com")
    }

    func testInitWithAliasAndHost() throws {
        XCTAssertNil(ConferenceAlias(alias: "", host: ""))
        XCTAssertNil(ConferenceAlias(alias: ".", host: "."))
        XCTAssertNil(ConferenceAlias(alias: "conference", host: "example"))
        XCTAssertNil(ConferenceAlias(alias: "@conference", host: "@example"))
        XCTAssertNil(ConferenceAlias(alias: "example.com", host: "conference"))
        XCTAssertNil(ConferenceAlias(alias: "conference", host: "example."))

        let name = try XCTUnwrap(ConferenceAlias(alias: "conference", host: "example.com"))
        XCTAssertEqual(name.uri, "conference@example.com")
        XCTAssertEqual(name.alias, "conference")
        XCTAssertEqual(name.host, "example.com")
    }
}
