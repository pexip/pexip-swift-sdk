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

    func testInitWithUrls() {
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

    func testInitWithUrl() {
        let url = "url"
        let username = "User"
        let password = "Password"
        let iceServer = IceServer(
            url: url,
            username: username,
            password: password
        )

        XCTAssertEqual(iceServer.urls, [url])
        XCTAssertEqual(iceServer.username, username)
        XCTAssertEqual(iceServer.password, password)
    }
}
