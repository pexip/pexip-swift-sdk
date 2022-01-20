import XCTest
@testable import Infinity

final class TokenTests: XCTestCase {
    func testDecoding() throws {
        let json = """
        {
            "status": "success",
            "result": {
                "token": "SE9TVAltZ...etc...zNiZjlmNjFhMTlmMTJiYTE%3D",
                "expires": "120",
                "participant_uuid": "2c34f35f-1060-438c-9e87-6c2dffbc9980",
                "display_name": "Alice",
                "stun": [{"url": "stun:stun.l.google.com:19302"}],
                "analytics_enabled": true,
                "version": {"pseudo_version": "25010.0.0", "version_id": "10"},
                "role": "HOST",
                "service_type": "conference",
                "chat_enabled": true,
                "current_service_type": "conference"
            }
        }
        """
        
        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try JSONDecoder().decode(ResponseBody<Token>.self, from: data)
        let token = response.result
        
        XCTAssertEqual(token.authToken, "SE9TVAltZ...etc...zNiZjlmNjFhMTlmMTJiYTE%3D")
        XCTAssertEqual(token.expires, 120)
        XCTAssertEqual(
            token.participantUUID.uuidString.lowercased(),
            "2c34f35f-1060-438c-9e87-6c2dffbc9980"
        )
        XCTAssertEqual(token.role, .host)
        XCTAssertEqual(token.serviceType, .conference)
    }
}
