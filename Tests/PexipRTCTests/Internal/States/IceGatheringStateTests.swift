import XCTest
import WebRTC
@testable import PexipRTC

final class IceGatheringStateTests: XCTestCase {
    func testInit() {
        XCTAssertEqual(IceGatheringState(.new), .new)
        XCTAssertEqual(IceGatheringState(.gathering), .gathering)
        XCTAssertEqual(IceGatheringState(.complete), .complete)
        XCTAssertEqual(IceGatheringState(.init(rawValue: 1001)!), .unknown)
    }

    func testDescription() {
        for state in IceGatheringState.allCases {
            XCTAssertEqual(state.description, state.rawValue.capitalized)
        }
    }
}
