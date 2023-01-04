import XCTest
import WebRTC
@testable import PexipRTC

final class IceConnectionStateTests: XCTestCase {
    func testInit() {
        XCTAssertEqual(IceConnectionState(.new), .new)
        XCTAssertEqual(IceConnectionState(.checking), .checking)
        XCTAssertEqual(IceConnectionState(.connected), .connected)
        XCTAssertEqual(IceConnectionState(.completed), .completed)
        XCTAssertEqual(IceConnectionState(.failed), .failed)
        XCTAssertEqual(IceConnectionState(.disconnected), .disconnected)
        XCTAssertEqual(IceConnectionState(.closed), .closed)
        XCTAssertEqual(IceConnectionState(.count), .count)
        XCTAssertEqual(IceConnectionState(.init(rawValue: 1001)!), .unknown)
    }

    func testDescription() {
        for state in IceConnectionState.allCases {
            XCTAssertEqual(state.description, state.rawValue.capitalized)
        }
    }
}
