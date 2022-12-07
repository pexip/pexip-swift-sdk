import XCTest
import WebRTC
import PexipCore
@testable import PexipRTC

final class RTCConfigurationDefaultTests: XCTestCase {
    private let iceServer = IceServer(
        kind: .stun,
        urls: [
            "stun:stun.l.google.com:19302",
            "stun:stun1.l.google.com:19302"
        ]
    )

    func testDefaultConfiguration() {
        let configuration = RTCConfiguration.defaultConfiguration(
            withIceServers: [iceServer],
            dscp: true
        )

        XCTAssertEqual(configuration.iceServers.count, 1)
        XCTAssertEqual(configuration.iceServers.first?.urlStrings, iceServer.urls)
        XCTAssertEqual(configuration.sdpSemantics, .unifiedPlan)
        XCTAssertEqual(configuration.bundlePolicy, .maxBundle)
        XCTAssertEqual(configuration.continualGatheringPolicy, .gatherContinually)
        XCTAssertEqual(configuration.rtcpMuxPolicy, .require)
        XCTAssertEqual(configuration.tcpCandidatePolicy, .enabled)
        XCTAssertTrue(configuration.enableDscp)
        XCTAssertTrue(configuration.enableImplicitRollback)
    }
}
