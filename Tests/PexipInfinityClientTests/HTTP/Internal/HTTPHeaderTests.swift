import XCTest
@testable import PexipInfinityClient

final class HTTPHeaderTests: XCTestCase {
    func testDescription() {
        let header = HTTPHeader(name: "Name", value: "value")
        XCTAssertEqual(header.description, "Name: value")
    }

    func testDefaultUserAgent() throws {
        let bundle = Bundle.main
        let name = try XCTUnwrap(bundle.object(forInfoDictionaryKey: "CFBundleName"))
        let version = try XCTUnwrap(
            bundle.object(
                forInfoDictionaryKey: "CFBundleShortVersionString"
            ) as? String
        )
        let header = HTTPHeader.defaultUserAgent

        XCTAssertEqual(header.name, "User-Agent")
        XCTAssertEqual(header.value, "\(name)/\(version)")
    }

    func testUserAgent() {
        let header = HTTPHeader.userAgent("value")
        XCTAssertEqual(header.name, "User-Agent")
        XCTAssertEqual(header.value, "value")
    }

    func testContentType() {
        let header = HTTPHeader.contentType("application/json")
        XCTAssertEqual(header.name, "Content-Type")
        XCTAssertEqual(header.value, "application/json")
    }

    func testAuthorization() {
        let header = HTTPHeader.authorization(username: "username", password: "password")
        XCTAssertEqual(header.name, "Authorization")
        XCTAssertEqual(
            header.value,
            "x-pexip-basic \(Data("username:password".utf8).base64EncodedString())"
        )
    }
}
