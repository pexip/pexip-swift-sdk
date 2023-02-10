#if os(iOS)

import XCTest
@testable import PexipScreenCapture

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

    func testBroadcastKeepAliveDate() {
        XCTAssertNil(userDefaults.broadcastKeepAliveDate)

        let date = Date()
        userDefaults.broadcastKeepAliveDate = date
        XCTAssertEqual(userDefaults.broadcastKeepAliveDate, date)

        userDefaults.broadcastKeepAliveDate = nil
        XCTAssertNil(userDefaults.broadcastKeepAliveDate)
    }
}

#endif
