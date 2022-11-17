import XCTest
import PexipCore
@testable import PexipMedia

final class MediaConnectionConfigTests: XCTestCase {
    func testInit() {
        let signaling = Signaling()
        let iceServer = IceServer(
            kind: .stun,
            urls: [
                "stun:stun.l.google.com:19302",
                "stun:stun1.l.google.com:19302"
            ]
        )
        let config = MediaConnectionConfig(
            signaling: signaling,
            iceServers: [iceServer],
            dscp: true,
            presentationInMain: true
        )

        XCTAssertEqual(config.signaling as? Signaling, signaling)
        XCTAssertEqual(config.iceServers, [iceServer])
        XCTAssertTrue(config.dscp)
        XCTAssertTrue(config.presentationInMain)
    }

    func testInitWithDefaults() {
        let signaling = Signaling()
        let config = MediaConnectionConfig(signaling: signaling)

        XCTAssertEqual(config.signaling as? Signaling, signaling)
        XCTAssertEqual(config.iceServers, [MediaConnectionConfig.googleIceServer])
        XCTAssertFalse(config.dscp)
        XCTAssertFalse(config.presentationInMain)
    }

    func testInitWithNoStunServers() {
        let signaling = Signaling()
        let iceServer = IceServer(
            kind: .turn,
            urls: ["url1", "url2"]
        )
        let config = MediaConnectionConfig(signaling: signaling, iceServers: [iceServer])

        XCTAssertEqual(config.signaling as? Signaling, signaling)
        XCTAssertEqual(config.iceServers, [iceServer] + [MediaConnectionConfig.googleIceServer])
        XCTAssertFalse(config.dscp)
        XCTAssertFalse(config.presentationInMain)
    }
}

// MARK: - Mocks

private struct Signaling: SignalingChannel, Hashable {
    var callId: UUID?
    var iceServers = [IceServer]()

    func sendOffer(
        callType: String,
        description: String,
        presentationInMain: Bool
    ) async throws -> String {
        return ""
    }

    func addCandidate(_ candidate: String, mid: String?) async throws {}
    func muteVideo(_ muted: Bool) async throws -> Bool { true }
    func muteAudio(_ muted: Bool) async throws -> Bool { true }
    func takeFloor() async throws -> Bool { true }
    func releaseFloor() async throws -> Bool { true }
    func dtmf(signals: DTMFSignals) async throws -> Bool { false }
}
