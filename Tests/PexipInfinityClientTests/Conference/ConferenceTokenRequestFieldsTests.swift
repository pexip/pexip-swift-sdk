import XCTest
@testable import PexipInfinityClient

final class ConferenceTokenRequestFieldsTests: XCTestCase {
    func testInit() {
        let identityProvider = IdentityProvider(name: "Name", id: UUID().uuidString)
        let ssoToken = UUID().uuidString
        let fields = ConferenceTokenRequestFields(
            displayName: "Name",
            conferenceExtension: "ext",
            idp: identityProvider,
            ssoToken: ssoToken,
            directMedia: false
        )

        XCTAssertEqual(fields.displayName, "Name")
        XCTAssertEqual(fields.conferenceExtension, "ext")
        XCTAssertEqual(fields.chosenIdpId, identityProvider.id)
        XCTAssertEqual(fields.ssoToken, ssoToken)
        XCTAssertFalse(fields.directMedia)
    }

    func testInitWithDefaults() {
        let fields = ConferenceTokenRequestFields(displayName: "Name")

        XCTAssertEqual(fields.displayName, "Name")
        XCTAssertNil(fields.conferenceExtension)
        XCTAssertNil(fields.chosenIdpId)
        XCTAssertNil(fields.ssoToken)
        XCTAssertTrue(fields.directMedia)
    }
}
