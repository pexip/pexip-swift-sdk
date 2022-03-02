import XCTest
import WebRTC
@testable import PexipVideo

final class WebRTCExtensionsTests: XCTestCase {
    // MARK: - Configuration

    func testConfigurationWithIceServers() {
        let urlStrings = [
            "stun:stun.l.google.com:19302",
            "stun:stun1.l.google.com:19302"
        ]
        let configuration = RTCConfiguration.configuration(
            withIceServers: urlStrings
        )

        XCTAssertEqual(configuration.iceServers.count, 1)
        XCTAssertTrue(configuration.iceServers.first?.urlStrings == urlStrings)
        XCTAssertEqual(configuration.sdpSemantics, .unifiedPlan)
        XCTAssertEqual(configuration.bundlePolicy, .balanced)
        XCTAssertEqual(configuration.continualGatheringPolicy, .gatherContinually)
        XCTAssertEqual(configuration.rtcpMuxPolicy, .require)
        XCTAssertEqual(configuration.tcpCandidatePolicy, .enabled)
        XCTAssertTrue(configuration.disableLinkLocalNetworks)
    }

    // MARK: - Media constraints

    func testMediaConstraintsEmpty() {
        let expectedConstraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: nil
        ).description

        let constraints = RTCMediaConstraints.empty.description

        XCTAssertEqual(constraints, expectedConstraints)
    }

    func testMediaConstraintsWithEnabledVideoAudio() {
        let expectedConstraints = RTCMediaConstraints(
            mandatoryConstraints: [
                kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue,
                kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueFalse
            ],
            optionalConstraints: [
                "internalSctpDataChannels": kRTCMediaConstraintsValueFalse,
                "DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue
            ]
        ).description

        let constraints = RTCMediaConstraints.constraints(
            withEnabledVideo: true,
            audio: false
        ).description

        XCTAssertEqual(constraints, expectedConstraints)
    }

    // MARK: - Signaling State

    func testSignalingStateDebugDescription() {
        func debugDescription(_ state: RTCSignalingState?) -> String? {
            state?.debugDescription
        }

        XCTAssertEqual(debugDescription(.stable), "Stable")
        XCTAssertEqual(debugDescription(.haveLocalOffer), "HaveLocalOffer")
        XCTAssertEqual(debugDescription(.haveLocalPrAnswer), "HaveLocalPrAnswer")
        XCTAssertEqual(debugDescription(.haveRemoteOffer), "HaveRemoteOffer")
        XCTAssertEqual(debugDescription(.haveRemotePrAnswer), "HaveRemotePrAnswer")
        XCTAssertEqual(debugDescription(.closed), "Closed")
        XCTAssertEqual(debugDescription(.init(rawValue: 1001)), "Unknown")
    }

    // MARK: - Connection State

    func testIceConnectionStateDebugDescription() {
        func debugDescription(_ state: RTCIceConnectionState?) -> String? {
            state?.debugDescription
        }

        XCTAssertEqual(debugDescription(.new), "New")
        XCTAssertEqual(debugDescription(.checking), "Checking")
        XCTAssertEqual(debugDescription(.connected), "Connected")
        XCTAssertEqual(debugDescription(.completed), "Completed")
        XCTAssertEqual(debugDescription(.failed), "Failed")
        XCTAssertEqual(debugDescription(.disconnected), "Disconnected")
        XCTAssertEqual(debugDescription(.closed), "Closed")
        XCTAssertEqual(debugDescription(.count), "Count")
        XCTAssertEqual(debugDescription(.init(rawValue: 1001)), "Unknown")
    }

    // MARK: - Ice Gathering State

    func testIceGatheringStateDebugDescription() {
        func debugDescription(_ state: RTCIceGatheringState?) -> String? {
            state?.debugDescription
        }

        XCTAssertEqual(debugDescription(.new), "New")
        XCTAssertEqual(debugDescription(.gathering), "Gathering")
        XCTAssertEqual(debugDescription(.complete), "Complete")
        XCTAssertEqual(debugDescription(.init(rawValue: 1001)), "Unknown")
    }
}
