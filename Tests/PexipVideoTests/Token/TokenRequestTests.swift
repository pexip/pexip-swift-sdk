import XCTest
@testable import PexipVideo

final class TokenRequestTests: XCTestCase {
    func testInit() {
        let identityProvider = IdentityProvider(name: "Name", uuid: UUID().uuidString)
        let ssoToken = UUID().uuidString
        let request = TokenRequest(
            displayName: "Name",
            pin: "1234",
            conferenceExtension: "ext",
            idp: identityProvider,
            ssoToken: ssoToken
        )

        XCTAssertEqual(request.displayName, "Name")
        XCTAssertEqual(request.pin, "1234")
        XCTAssertEqual(request.conferenceExtension, "ext")
        XCTAssertEqual(request.idp, identityProvider)
        XCTAssertEqual(request.ssoToken, ssoToken)
    }

    func testInitWithEmptyPin() {
        let request = TokenRequest(displayName: "Name", pin: "")

        XCTAssertEqual(request.displayName, "Name")
        XCTAssertEqual(request.pin, "none")
        XCTAssertNil(request.conferenceExtension)
        XCTAssertNil(request.idp)
        XCTAssertNil(request.ssoToken)
    }
}
