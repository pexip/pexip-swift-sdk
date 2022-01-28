import XCTest
@testable import PexipVideo

final class AuthTokenTests: XCTestCase {
    private var calendar: Calendar!

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        calendar = Calendar.current
        calendar.timeZone = try XCTUnwrap(TimeZone(abbreviation: "GMT"))
    }
    
    func testTokenDecoding() throws {
        let json = """
        {
            "status": "success",
            "result": {
                "token": "SE9TVAltZ...etc...zNiZjlmNjFhMTlmMTJiYTE%3D",
                "expires": "120",
                "role": "HOST"
            }
        }
        """
        
        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try JSONDecoder().decode(ResponseContainer<AuthToken>.self, from: data)
        let token = response.result
        
        XCTAssertEqual(token.value, "SE9TVAltZ...etc...zNiZjlmNjFhMTlmMTJiYTE%3D")
        XCTAssertEqual(token.expires, 120)
        XCTAssertEqual(token.role, .host)
        XCTAssertFalse(token.isExpired())
    }
    
    func testTokenExpiration() throws {
        let createdAt = try XCTUnwrap(
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
        
        let token = AuthToken(
            value: "SE9TVAltZ...etc...zNiZjlmNjFhMTlmMTJiYTE%3D",
            expires: "120",
            role: .guest,
            createdAt: createdAt
        )
        
        // createdAt + 120 seconds
        XCTAssertEqual(
            token.expiresAt,
            createdAt.addingTimeInterval(120)
        )
        
        // createdAt + 120/2 seconds
        XCTAssertEqual(
            token.refreshDate,
            createdAt.addingTimeInterval(120/2)
        )
        
        // Expired, createdAt + 240 seconds
        XCTAssertTrue(
            token.isExpired(
                currentDate: createdAt.addingTimeInterval(240)
            )
        )
        
        // Not expired, createdAt + 60 seconds
        XCTAssertFalse(
            token.isExpired(
                currentDate: createdAt.addingTimeInterval(60)
            )
        )
    }
}
