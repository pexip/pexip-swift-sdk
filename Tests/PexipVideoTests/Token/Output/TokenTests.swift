import XCTest
@testable import PexipVideo

final class TokenTests: XCTestCase {
    private var calendar: Calendar!

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        calendar = Calendar.current
        calendar.timeZone = try XCTUnwrap(TimeZone(abbreviation: "GMT"))
    }

    // swiftlint:disable function_body_length
    func testDecoding() throws {
        let tokenValue = "SE9TVAltZ...etc...zNiZjlmNjFhMTlmMTJiYTE%3D"
        let json = """
        {
            "status": "success",
            "result": {
                "token": "\(tokenValue)",
                "expires": "120",
                "role": "HOST",
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

        let date = Date()
        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try JSONDecoder().decode(
            ResponseContainer<Token>.self,
            from: data
        )
        var token = response.result

        XCTAssertEqual(token.value, tokenValue)
        XCTAssertEqual(token.expires, 120)
        XCTAssertEqual(token.role, .host)
        XCTAssertFalse(token.isExpired())

        token.update(value: tokenValue, expires: "120", updatedAt: date)

        XCTAssertEqual(
            token,
            Token(
                value: tokenValue,
                updatedAt: date,
                participantId: try XCTUnwrap(
                    UUID(uuidString: "2c34f35f-1060-438c-9e87-6c2dffbc9980")
                ),
                role: .host,
                displayName: "Alice",
                serviceType: "conference",
                conferenceName: "Conference",
                stun: [.init(url: "stun:stun.l.google.com:19302")],
                expiresString: "120"
            )
        )
    }

    func testUpdate() throws {
        let date = Date()
        var token = Token(
            value: "token_value",
            updatedAt: date,
            participantId: try XCTUnwrap(
                UUID(uuidString: "2c34f35f-1060-438c-9e87-6c2dffbc9980")
            ),
            role: .host,
            displayName: "Alice",
            serviceType: "conference",
            conferenceName: "Conference",
            stun: [.init(url: "stun:stun.l.google.com:19302")],
            expiresString: "120"
        )

        token.update(value: "new_token_value", expires: "240", updatedAt: date)

        XCTAssertEqual(token.value, "new_token_value")
        XCTAssertEqual(token.expires, 240)
        XCTAssertEqual(token.updatedAt, date)
    }

    func testTokenExpiration() throws {
        let updatedAt = try XCTUnwrap(
            DateComponents(
                calendar: calendar,
                year: 2022,
                month: 1,
                day: 25,
                hour: 16,
                minute: 50,
                second: 11
            ).date
        )

        let token = Token(
            value: "token_value",
            updatedAt: updatedAt,
            participantId: try XCTUnwrap(
                UUID(uuidString: "2c34f35f-1060-438c-9e87-6c2dffbc9980")
            ),
            role: .host,
            displayName: "Alice",
            serviceType: "conference",
            conferenceName: "Conference",
            stun: [.init(url: "stun:stun.l.google.com:19302")],
            expiresString: "120"
        )

        // updatedAt + 120 seconds
        XCTAssertEqual(
            token.expiresAt,
            updatedAt.addingTimeInterval(120)
        )

        // updatedAt + 120/2 seconds
        XCTAssertEqual(
            token.refreshDate,
            updatedAt.addingTimeInterval(120/2)
        )

        // Expired, updatedAt + 240 seconds
        XCTAssertTrue(
            token.isExpired(
                currentDate: updatedAt.addingTimeInterval(240)
            )
        )

        // Not expired, updatedAt + 60 seconds
        XCTAssertFalse(
            token.isExpired(
                currentDate: updatedAt.addingTimeInterval(60)
            )
        )
    }
}
