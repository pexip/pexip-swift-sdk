import XCTest
@testable import PexipInfinityClient

final class ConferenceTokenTests: XCTestCase {
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
                "current_service_type": "conference",
                "turn": [{
                    "urls": [
                        "turn:turn.pexip.com:1234"
                    ],
                    "username": "username",
                    "credential": "password"
                }]
            }
        }
        """

        let date = Date()
        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try JSONDecoder().decode(
            ResponseContainer<ConferenceToken>.self,
            from: data
        )
        var token = response.result

        XCTAssertEqual(token.value, tokenValue)
        XCTAssertEqual(token.expires, 120)
        XCTAssertEqual(token.role, .host)
        XCTAssertFalse(token.isExpired())

        token = token.updating(value: tokenValue, expires: "120", updatedAt: date)

        XCTAssertEqual(
            token,
            ConferenceToken(
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
                turn: [.init(
                    urls: ["turn:turn.pexip.com:1234"],
                    username: "username",
                    credential: "password"
                )],
                chatEnabled: true,
                analyticsEnabled: true,
                expiresString: "120",
                version: Version(versionId: "10", pseudoVersion: "25010.0.0")
            )
        )
    }

    func testUpdating() throws {
        let date = Date()
        let token = ConferenceToken(
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
            turn: nil,
            chatEnabled: true,
            analyticsEnabled: false,
            expiresString: "120",
            version: Version(versionId: "10", pseudoVersion: "25010.0.0")
        )

        let newToken = token.updating(
            value: "new_token_value",
            expires: "240",
            updatedAt: date
        )

        XCTAssertEqual(newToken.value, "new_token_value")
        XCTAssertEqual(newToken.expires, 240)
        XCTAssertEqual(newToken.updatedAt, date)
        XCTAssertEqual(newToken.participantId, token.participantId)
        XCTAssertEqual(newToken.role, token.role)
        XCTAssertEqual(newToken.displayName, token.displayName)
        XCTAssertEqual(newToken.serviceType, token.serviceType)
        XCTAssertEqual(newToken.conferenceName, token.conferenceName)
        XCTAssertEqual(newToken.stun, token.stun)
        XCTAssertTrue(newToken.chatEnabled)
        XCTAssertEqual(newToken.version, token.version)
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

        let token = ConferenceToken(
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
            turn: [],
            chatEnabled: true,
            analyticsEnabled: false,
            expiresString: "120",
            version: Version(versionId: "10", pseudoVersion: "25010.0.0")
        )

        // updatedAt + 120 seconds
        XCTAssertEqual(
            token.expiresAt,
            updatedAt.addingTimeInterval(120)
        )

        // updatedAt + 120/2 seconds
        XCTAssertEqual(
            token.refreshDate,
            updatedAt.addingTimeInterval(120 / 2)
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

    func testTokenWrongExpiresString() {
        let token = ConferenceToken(
            value: UUID().uuidString,
            participantId: UUID(),
            role: .guest,
            displayName: "Name",
            serviceType: "test",
            conferenceName: "Conference",
            stun: [],
            turn: [],
            chatEnabled: false,
            analyticsEnabled: true,
            expiresString: "test",
            version: Version(versionId: "10", pseudoVersion: "25010.0.0")
        )
        XCTAssertEqual(token.expires, 0)
    }

    func testIceServersWithStunAndTurn() {
        let token = ConferenceToken.randomToken(
            stun: ["url1", "url2"],
            turn: [ConferenceToken.Turn(
                urls: ["url1", "url2"],
                username: "username",
                credential: "password"
            )]
        )
        XCTAssertEqual(
            token.iceServers,
            [
                IceServer(url: "url1"),
                IceServer(url: "url2"),
                IceServer(
                    urls: ["url1", "url2"],
                    username: "username",
                    password: "password"
                )
            ]
        )
    }

    func testIceServersWithoutStunAndTurn() {
        let token = ConferenceToken.randomToken(stun: nil, turn: nil)
        XCTAssertTrue(token.iceServers.isEmpty)
    }

    func testIceServersWithStun() {
        let token = ConferenceToken.randomToken(
            stun: ["url1", "url2"],
            turn: nil
        )
        XCTAssertEqual(
            token.iceServers,
            [IceServer(url: "url1"), IceServer(url: "url2")]
        )
    }

    func testIceServersWithTurn() {
        let token = ConferenceToken.randomToken(
            stun: [],
            turn: [
                ConferenceToken.Turn(
                    urls: ["url1", "url2"],
                    username: "username",
                    credential: "password"
                ),
                ConferenceToken.Turn(
                    urls: ["url3", "url4"],
                    username: "username2",
                    credential: "password2"
                )
            ]
        )
        XCTAssertEqual(
            token.iceServers,
            [
                IceServer(
                    urls: ["url1", "url2"],
                    username: "username",
                    password: "password"
                ),
                IceServer(
                    urls: ["url3", "url4"],
                    username: "username2",
                    password: "password2"
                )
            ]
        )
    }
}
