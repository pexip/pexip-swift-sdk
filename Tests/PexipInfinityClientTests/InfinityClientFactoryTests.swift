import XCTest
@testable import PexipInfinityClient

final class InfinityClientFactoryTests: XCTestCase {
    private var factory: InfinityClientFactory!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        factory = InfinityClientFactory()
    }

    // MARK: - Tests

    func testInfinityService() {
        XCTAssertTrue(factory.infinityService() is DefaultInfinityService)
    }

    func testNodeResolver() {
        XCTAssertTrue(factory.nodeResolver(dnssec: false) is DefaultNodeResolver)
    }

    func testRegistration() throws {
        let registration = factory.registration(
            node: try XCTUnwrap(URL(string: "https://example.com/conference")),
            deviceAlias: try XCTUnwrap(DeviceAlias(uri: "device@conference.com")),
            token: .randomToken()
        )
        XCTAssertTrue(registration is DefaultRegistration)
    }

    func testConference() throws {
        let conference = factory.conference(
            service: factory.infinityService(),
            node: try XCTUnwrap(URL(string: "https://example.com/conference")),
            alias: try XCTUnwrap(ConferenceAlias(uri: "conference@conference.com")),
            token: .randomToken()
        )
        XCTAssertTrue(conference is DefaultConference)
    }
}
