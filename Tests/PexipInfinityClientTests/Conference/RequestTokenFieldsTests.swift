import XCTest
@testable import PexipInfinityClient

final class RequestTokenFieldsTests: XCTestCase {
    func testInit() {
        let identityProvider = IdentityProvider(name: "Name", id: UUID().uuidString)
        let ssoToken = UUID().uuidString
        let request = RequestTokenFields(
            displayName: "Name",
            conferenceExtension: "ext",
            idp: identityProvider,
            ssoToken: ssoToken
        )

        XCTAssertEqual(request.displayName, "Name")
        XCTAssertEqual(request.conferenceExtension, "ext")
        XCTAssertEqual(request.chosenIdpId, identityProvider.id)
        XCTAssertEqual(request.ssoToken, ssoToken)
    }

    func testInitWithDefaults() {
        let request = RequestTokenFields(displayName: "Name")

        XCTAssertEqual(request.displayName, "Name")
        XCTAssertNil(request.conferenceExtension)
        XCTAssertNil(request.chosenIdpId)
        XCTAssertNil(request.ssoToken)
    }
}
