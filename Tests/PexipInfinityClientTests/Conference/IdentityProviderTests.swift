import XCTest
@testable import PexipInfinityClient

final class IdentityProviderTests: XCTestCase {
    func testInit() {
        let uuid = UUID().uuidString
        let identityProvider = IdentityProvider(name: "Name", id: uuid)

        XCTAssertEqual(identityProvider.name, "Name")
        XCTAssertEqual(identityProvider.id, uuid)
    }
}
