import XCTest
@testable import WebRTC
@testable import PexipRTC

final class SignalingStateTests: XCTestCase {
    func testInit() {
        XCTAssertEqual(SignalingState(.stable), .stable)
        XCTAssertEqual(SignalingState(.haveLocalOffer), .haveLocalOffer)
        XCTAssertEqual(SignalingState(.haveLocalPrAnswer), .haveLocalPrAnswer)
        XCTAssertEqual(SignalingState(.haveRemoteOffer), .haveRemoteOffer)
        XCTAssertEqual(SignalingState(.haveRemotePrAnswer), .haveRemotePrAnswer)
        XCTAssertEqual(SignalingState(.closed), .closed)
        XCTAssertEqual(SignalingState(.init(rawValue: 1001)!), .unknown)
    }

    func testDescription() {
        for state in SignalingState.allCases {
            XCTAssertEqual(state.description, state.rawValue.capitalized)
        }
    }
}
