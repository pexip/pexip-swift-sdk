import XCTest
@testable import PexipMedia

final class IceServerTests: XCTestCase {
    func testInitWithDefaults() {
        let urls = ["url1", "url2"]
        let iceServer = IceServer(urls: urls)

        XCTAssertEqual(iceServer.urls, urls)
        XCTAssertNil(iceServer.username)
        XCTAssertNil(iceServer.password)
    }

    func testInit() {
        let urls = ["url1", "url2"]
        let username = "User"
        let password = "Password"
        let iceServer = IceServer(
            urls: urls,
            username: username,
            password: password
        )

        XCTAssertEqual(iceServer.urls, urls)
        XCTAssertEqual(iceServer.username, username)
        XCTAssertEqual(iceServer.password, password)
    }
}
