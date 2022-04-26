import XCTest
import WebRTC
@testable import PexipRTC

final class RTCRtpTransceiverInitDirectionTests: XCTestCase {
    func testInitWithDirection() {
        XCTAssertEqual(RTCRtpTransceiverInit(direction: .sendOnly).direction, .sendOnly)
        XCTAssertEqual(RTCRtpTransceiverInit(direction: .recvOnly).direction, .recvOnly)
        XCTAssertEqual(RTCRtpTransceiverInit(direction: .sendRecv).direction, .sendRecv)
        XCTAssertEqual(RTCRtpTransceiverInit(direction: .inactive).direction, .inactive)
        XCTAssertEqual(RTCRtpTransceiverInit(direction: .stopped).direction, .stopped)
    }
}
