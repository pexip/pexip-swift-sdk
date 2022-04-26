import XCTest
import WebRTC
@testable import PexipRTC

final class WebRTCVideoEncoderFactoryVP8Tests: XCTestCase {
    private var factory: RTCVideoEncoderFactoryVP8!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        factory = RTCVideoEncoderFactoryVP8()
    }

    // MARK: - Tests

    func testCreateEncoder() {
        XCTAssertNotNil(factory.createEncoder(.init(name: kRTCVp8CodecName)))
        XCTAssertNil(factory.createEncoder(.init(name: kRTCVp9CodecName)))
    }

    func testSupportedCodecs() {
        XCTAssertEqual(
            factory.supportedCodecs(),
            [RTCVideoCodecInfo(name: kRTCVp8CodecName)]
        )
    }
}
