import XCTest
import WebRTC
import PexipMedia
@testable import PexipRTC

final class MediaConnectionStateWebRTCTests: XCTestCase {
    func testInit() {
        XCTAssertEqual(MediaConnectionState(.new), .new)
        XCTAssertEqual(MediaConnectionState(.connecting), .connecting)
        XCTAssertEqual(MediaConnectionState(.connected), .connected)
        XCTAssertEqual(MediaConnectionState(.disconnected), .disconnected)
        XCTAssertEqual(MediaConnectionState(.failed), .failed)
        XCTAssertEqual(MediaConnectionState(.closed), .closed)
        XCTAssertEqual(MediaConnectionState(.init(rawValue: 1001)!), .unknown)
    }

    func testDescription() {
        for state in MediaConnectionState.allCases {
            XCTAssertEqual(state.description, state.rawValue.capitalized)
        }
    }
}
