import XCTest
import WebRTC
@testable import PexipRTC

final class RTCVideoDecoderFactoryVP8Tests: XCTestCase {
    private var factory: RTCVideoDecoderFactoryVP8!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        factory = RTCVideoDecoderFactoryVP8()
    }

    // MARK: - Tests

    func testCreateEncoder() {
        XCTAssertNotNil(factory.createDecoder(.init(name: kRTCVp8CodecName)))
        XCTAssertNil(factory.createDecoder(.init(name: kRTCVp9CodecName)))
    }

    func testSupportedCodecs() {
        XCTAssertEqual(
            factory.supportedCodecs(),
            [RTCVideoCodecInfo(name: kRTCVp8CodecName)]
        )
    }
}
