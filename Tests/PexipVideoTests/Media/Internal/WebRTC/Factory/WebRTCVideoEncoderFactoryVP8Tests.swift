import XCTest
import WebRTC
@testable import PexipVideo

final class WebRTCVideoEncoderFactoryVP8Tests: XCTestCase {
    private var factory: WebRTCVideoEncoderFactoryVP8!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        factory = WebRTCVideoEncoderFactoryVP8()
    }

    // MARK: - Tests

    func testCreateEncoder() {
        XCTAssertNotNil(factory.createEncoder(.init(name: kRTCVideoCodecVp8Name)))
        XCTAssertNil(factory.createEncoder(.init(name: kRTCVideoCodecVp9Name)))
    }

    func testSupportedCodecs() {
        XCTAssertEqual(
            factory.supportedCodecs(),
            [RTCVideoCodecInfo(name: kRTCVideoCodecVp8Name)]
        )
    }
}
