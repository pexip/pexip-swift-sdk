#if os(iOS)

import XCTest
@testable import PexipMedia

final class UserDefaultsBroadcastTests: XCTestCase {
    private let suiteName = "Test User Defaults"
    private var userDefaults: UserDefaults!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    // MARK: - Tests

    func testBroadcastFps() {
        XCTAssertNil(userDefaults.broadcastFps)

        userDefaults.broadcastFps = 15
        XCTAssertEqual(userDefaults.broadcastFps, 15)

        userDefaults.broadcastFps = nil
        XCTAssertNil(userDefaults.broadcastFps)
    }
}

#endif
