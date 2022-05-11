import XCTest
@testable import PexipMedia

final class MediaConnectionConfigTests: XCTestCase {
    func testInit() {
        let signaling = Signaling()
        let iceServer = IceServer(urls: [
            "stun:stun.l.google.com:19302",
            "stun:stun1.l.google.com:19302"
        ])
        let config = MediaConnectionConfig(
            signaling: signaling,
            iceServers: [iceServer],
            presentationInMain: true
        )

        XCTAssertEqual(config.signaling as? Signaling, signaling)
        XCTAssertEqual(config.iceServers, [iceServer])
        XCTAssertTrue(config.presentationInMain)
    }

    func testInitWithDefaults() {
        let signaling = Signaling()
        let config = MediaConnectionConfig(signaling: signaling)

        XCTAssertEqual(config.signaling as? Signaling, signaling)
        XCTAssertEqual(config.iceServers, [MediaConnectionConfig.googleIceServer])
        XCTAssertFalse(config.presentationInMain)
    }
}

// MARK: - Mocks

private struct Signaling: MediaConnectionSignaling, Hashable {
    func sendOffer(
        callType: String,
        description: String,
        presentationInMain: Bool
    ) async throws -> String {
        return ""
    }

    func addCandidate(sdp: String, mid: String?) async throws {}
    func muteVideo(_ muted: Bool) async throws {}
    func muteAudio(_ muted: Bool) async throws {}
}
