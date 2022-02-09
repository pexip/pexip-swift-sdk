import XCTest
@testable import PexipVideo

final class ConnectionDetailsTests: XCTestCase {
    func testDecoding() throws {
        let json = """
        {
            "status": "success",
            "result": {
                "participant_uuid": "2c34f35f-1060-438c-9e87-6c2dffbc9980",
                "display_name": "Alice",
                "conference_name": "Conference",
                "stun": [{"url": "stun:stun.l.google.com:19302"}],
                "analytics_enabled": true,
                "version": {"pseudo_version": "25010.0.0", "version_id": "10"},
                "service_type": "conference",
                "chat_enabled": true,
                "current_service_type": "conference"
            }
        }
        """

        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try JSONDecoder().decode(
            ResponseContainer<ConnectionDetails>.self,
            from: data
        )
        let details = response.result

        XCTAssertEqual(
            details.participantUUID.uuidString.lowercased(),
            "2c34f35f-1060-438c-9e87-6c2dffbc9980"
        )
        XCTAssertEqual(details.serviceType, .conference)
    }
}
