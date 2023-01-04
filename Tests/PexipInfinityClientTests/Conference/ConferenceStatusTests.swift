import XCTest
@testable import PexipInfinityClient

final class ConferenceStatusTests: XCTestCase {
    func testStatusDecoding() throws {
        let status = ConferenceStatus(
            started: true,
            locked: false,
            allMuted: false,
            guestsMuted: false,
            presentationAllowed: true,
            directMedia: false,
            liveCaptionsAvailable: true
        )
        let json = """
        {
            "started": \(status.started),
            "locked": \(status.locked),
            "all_muted": \(status.allMuted),
            "guests_muted": \(status.guestsMuted),
            "presentation_allowed": \(status.presentationAllowed),
            "direct_media": \(status.directMedia),
            "live_captions_available": \(status.liveCaptionsAvailable)
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let decodedStatus = try JSONDecoder().decode(
            ConferenceStatus.self,
            from: data
        )

        XCTAssertEqual(decodedStatus, status)
    }

    func testDecodingWithEmptyJSONObject() throws {
        let json = "{}"
        let data = try XCTUnwrap(json.data(using: .utf8))
        let decodedStatus = try JSONDecoder().decode(
            ConferenceStatus.self,
            from: data
        )

        XCTAssertFalse(decodedStatus.started)
        XCTAssertFalse(decodedStatus.locked)
        XCTAssertFalse(decodedStatus.allMuted)
        XCTAssertFalse(decodedStatus.guestsMuted)
        XCTAssertFalse(decodedStatus.presentationAllowed)
        XCTAssertFalse(decodedStatus.directMedia)
        XCTAssertFalse(decodedStatus.liveCaptionsAvailable)
    }
}
