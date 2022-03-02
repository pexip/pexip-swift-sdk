import XCTest
import WebRTC
@testable import PexipVideo

final class WebRTCVideoDecoderFactoryVP8Tests: XCTestCase {
    private var factory: WebRTCVideoDecoderFactoryVP8!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        factory = WebRTCVideoDecoderFactoryVP8()
    }

    // MARK: - Tests

    func testCreateDecoder() {
        XCTAssertNotNil(factory.createDecoder(.init(name: kRTCVideoCodecVp8Name)))
        XCTAssertNil(factory.createDecoder(.init(name: kRTCVideoCodecVp9Name)))
    }

    func testSupportedCodecs() {
        XCTAssertEqual(
            factory.supportedCodecs(),
            [RTCVideoCodecInfo(name: kRTCVideoCodecVp8Name)]
        )
    }
}
