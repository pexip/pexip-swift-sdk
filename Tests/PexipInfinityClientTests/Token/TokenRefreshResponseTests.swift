import XCTest
@testable import PexipInfinityClient

final class TokenRefreshResponseTests: XCTestCase {
    func testInit() {
        let token = UUID().uuidString
        let expires = "120"
        let response = TokenRefreshResponse(token: token, expires: expires)

        XCTAssertEqual(response.token, token)
        XCTAssertEqual(response.expires, expires)
    }
}
