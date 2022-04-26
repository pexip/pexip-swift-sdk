import XCTest
import WebRTC
@testable import PexipRTC

final class ConnectionStateTests: XCTestCase {
    func testInit() {
        XCTAssertEqual(ConnectionState(.new), .new)
        XCTAssertEqual(ConnectionState(.connecting), .connecting)
        XCTAssertEqual(ConnectionState(.connected), .connected)
        XCTAssertEqual(ConnectionState(.disconnected), .disconnected)
        XCTAssertEqual(ConnectionState(.failed), .failed)
        XCTAssertEqual(ConnectionState(.closed), .closed)
        XCTAssertEqual(ConnectionState(.init(rawValue: 1001)!), .unknown)
    }

    func testDescription() {
        for state in ConnectionState.allCases {
            XCTAssertEqual(state.description, state.rawValue.capitalized)
        }
    }
}
