import XCTest
@testable import PexipInfinityClient

final class ConferenceEventTests: XCTestCase {
    func testConferenceStatusDecoding() throws {
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

        XCTAssertEqual(decodedStatus.started, status.started)
        XCTAssertEqual(decodedStatus.locked, status.locked)
        XCTAssertEqual(decodedStatus.allMuted, status.allMuted)
        XCTAssertEqual(decodedStatus.guestsMuted, status.guestsMuted)
        XCTAssertEqual(
            decodedStatus.presentationAllowed,
            status.presentationAllowed
        )
        XCTAssertEqual(decodedStatus.directMedia, status.directMedia)
        XCTAssertEqual(
            decodedStatus.liveCaptionsAvailable,
            status.liveCaptionsAvailable
        )
    }

    func testConferenceStatusDecodingWithEmptyJSONObject() throws {
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
