import XCTest
@testable import PexipVideo

final class IdentityProviderTests: XCTestCase {
    func testInit() {
        let uuid = UUID().uuidString
        let identityProvider = IdentityProvider(name: "Name", uuid: uuid)

        XCTAssertEqual(identityProvider.name, "Name")
        XCTAssertEqual(identityProvider.uuid, uuid)
    }
}
