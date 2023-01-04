import XCTest
import WebRTC
@testable import PexipRTC

final class DataChannelStateTests: XCTestCase {
    func testInit() {
        XCTAssertEqual(DataChannelState(.connecting), .connecting)
        XCTAssertEqual(DataChannelState(.open), .open)
        XCTAssertEqual(DataChannelState(.closing), .closing)
        XCTAssertEqual(DataChannelState(.closed), .closed)
        XCTAssertEqual(DataChannelState(.connecting), .connecting)
        XCTAssertEqual(DataChannelState(.init(rawValue: 1001)!), .unknown)
    }

    func testDescription() {
        for state in IceConnectionState.allCases {
            XCTAssertEqual(state.description, state.rawValue.capitalized)
        }
    }
}
