import XCTest
import Combine
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

        XCTAssertTrue(config.signaling is Signaling)
        XCTAssertEqual(config.iceServers, [iceServer])
        XCTAssertTrue(config.dscp)
        XCTAssertTrue(config.presentationInMain)
    }

    func testInitWithDefaults() {
        let signaling = Signaling()
        let config = MediaConnectionConfig(signaling: signaling)

        XCTAssertTrue(config.signaling is Signaling)
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

        XCTAssertTrue(config.signaling is Signaling)
        XCTAssertEqual(config.iceServers, [iceServer] + [MediaConnectionConfig.googleIceServer])
        XCTAssertFalse(config.dscp)
        XCTAssertFalse(config.presentationInMain)
    }
}

// MARK: - Mocks

private final class Signaling: SignalingChannel {
    var callId: String?
    var iceServers = [IceServer]()
    var data: DataChannel?
    var eventPublisher: AnyPublisher<SignalingEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    private let eventSubject = PassthroughSubject<SignalingEvent, Never>()

    func sendOffer(
        callType: String,
        description: String,
        presentationInMain: Bool
    ) async throws -> String? {
        return ""
    }

    func sendAnswer(_ description: String) async throws {}
    func addCandidate(_ candidate: String, mid: String?) async throws {}
    func muteVideo(_ muted: Bool) async throws -> Bool { true }
    func muteAudio(_ muted: Bool) async throws -> Bool { true }
    func takeFloor() async throws -> Bool { true }
    func releaseFloor() async throws -> Bool { true }
    func dtmf(signals: DTMFSignals) async throws -> Bool { false }
}
