import XCTest
import WebRTC
@testable import PexipRTC

final class VideoDecoderFactoryVP8Tests: XCTestCase {
    private var factory: VideoDecoderFactoryVP8!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        factory = VideoDecoderFactoryVP8()
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
