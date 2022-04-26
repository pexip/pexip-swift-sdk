import XCTest
import WebRTC
@testable import PexipRTC

final class RTCConfigurationDefaultTests: XCTestCase {
    private let urlStrings = [
        "stun:stun.l.google.com:19302",
        "stun:stun1.l.google.com:19302"
    ]

    func testDefaultConfiguration() {
        let configuration = RTCConfiguration.defaultConfiguration(
            withIceServers: urlStrings,
            useGoogleStunServersAsBackup: false
        )

        XCTAssertEqual(configuration.iceServers.count, 1)
        XCTAssertEqual(configuration.iceServers.first?.urlStrings, urlStrings)
        XCTAssertEqual(configuration.sdpSemantics, .unifiedPlan)
        XCTAssertEqual(configuration.bundlePolicy, .balanced)
        XCTAssertEqual(configuration.continualGatheringPolicy, .gatherContinually)
        XCTAssertEqual(configuration.rtcpMuxPolicy, .require)
        XCTAssertEqual(configuration.tcpCandidatePolicy, .enabled)
        XCTAssertTrue(configuration.disableLinkLocalNetworks)
    }

    func testDefaultConfigurationWithIceServersAndBackupEnabled() {
        let configuration = RTCConfiguration.defaultConfiguration(
            withIceServers: urlStrings,
            useGoogleStunServersAsBackup: true
        )

        XCTAssertEqual(configuration.iceServers.count, 1)
        XCTAssertEqual(configuration.iceServers.first?.urlStrings, urlStrings)
    }

    func testDefaultConfigurationWithoutIceServersAndBackupEnabled() {
        let configuration = RTCConfiguration.defaultConfiguration(
            withIceServers: [],
            useGoogleStunServersAsBackup: true
        )

        XCTAssertEqual(configuration.iceServers.count, 1)
        XCTAssertEqual(
            configuration.iceServers.first?.urlStrings,
            RTCConfiguration.googleStunServers
        )
    }
}
