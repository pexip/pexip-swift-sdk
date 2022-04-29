import XCTest
import WebRTC
import PexipMedia
@testable import PexipRTC

final class RTCConfigurationDefaultTests: XCTestCase {
    private let iceServer = IceServer(urls: [
        "stun:stun.l.google.com:19302",
        "stun:stun1.l.google.com:19302"
    ])

    func testDefaultConfiguration() {
        let configuration = RTCConfiguration.defaultConfiguration(
            withIceServers: [iceServer]
        )

        XCTAssertEqual(configuration.iceServers.count, 1)
        XCTAssertEqual(configuration.iceServers.first?.urlStrings, iceServer.urls)
        XCTAssertEqual(configuration.sdpSemantics, .unifiedPlan)
        XCTAssertEqual(configuration.bundlePolicy, .balanced)
        XCTAssertEqual(configuration.continualGatheringPolicy, .gatherContinually)
        XCTAssertEqual(configuration.rtcpMuxPolicy, .require)
        XCTAssertEqual(configuration.tcpCandidatePolicy, .enabled)
    }
}
