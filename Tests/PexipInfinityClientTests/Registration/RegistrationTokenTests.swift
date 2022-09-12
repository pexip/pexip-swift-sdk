import XCTest
@testable import PexipInfinityClient

final class RegistrationTokenTests: XCTestCase {
    private var calendar: Calendar!

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        calendar = Calendar.current
        calendar.timeZone = try XCTUnwrap(TimeZone(abbreviation: "GMT"))
    }

    // MARK: - Tests

    func testName() {
        XCTAssertEqual(RegistrationToken.name, "Registration token")
    }

    func testDecoding() throws {
        let tokenValue = "SE9TVAltZ...etc...zNiZjlmNjFhMTlmMTJiYTE%3D"
        let registrationId = UUID()
        let directoryEnabled = Bool.random()
        let routeViaRegistrar = Bool.random()
        let json = """
        {
            "status": "success",
            "result": {
                "token": "\(tokenValue)",
                "registration_uuid": "\(registrationId)",
                "directory_enabled": \(directoryEnabled),
                "route_via_registrar": \(routeViaRegistrar),
                "version": {"pseudo_version": "25010.0.0", "version_id": "10"},
                "expires": "120"
            }
        }
        """

        let date = Date()
        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try JSONDecoder().decode(
            ResponseContainer<RegistrationToken>.self,
            from: data
        )
        var token = response.result

        XCTAssertEqual(token.value, tokenValue)
        XCTAssertEqual(token.expires, 120)
        XCTAssertFalse(token.isExpired())

        token = token.updating(value: tokenValue, expires: "120", updatedAt: date)

        XCTAssertEqual(
            token,
            RegistrationToken(
                value: tokenValue,
                updatedAt: date,
                registrationId: registrationId,
                directoryEnabled: directoryEnabled,
                routeViaRegistrar: routeViaRegistrar,
                expiresString: "120",
                version: Version(versionId: "10", pseudoVersion: "25010.0.0")
            )
        )
    }

    func testUpdating() throws {
        let date = Date()
        let registrationId = UUID()
        let token = RegistrationToken(
            value: "token_value",
            updatedAt: date,
            registrationId: registrationId,
            directoryEnabled: true,
            routeViaRegistrar: false,
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
        XCTAssertEqual(newToken.registrationId, registrationId)
        XCTAssertTrue(newToken.directoryEnabled)
        XCTAssertFalse(newToken.routeViaRegistrar)
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

        let token = RegistrationToken(
            value: "token_value",
            updatedAt: updatedAt,
            registrationId: UUID(),
            directoryEnabled: true,
            routeViaRegistrar: false,
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
        let token = RegistrationToken(
            value: UUID().uuidString,
            registrationId: UUID(),
            directoryEnabled: true,
            routeViaRegistrar: false,
            expiresString: "test",
            version: Version(versionId: "10", pseudoVersion: "25010.0.0")
        )
        XCTAssertEqual(token.expires, 0)
    }
}
