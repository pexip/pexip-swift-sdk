import XCTest
@testable import PexipInfinityClient

final class TokenErrorTests: XCTestCase {
    private let decoder = JSONDecoder()

    // MARK: - Tests

    func testDecodingPinRequiredWithRequiredPin() throws {
        let data = """
        {
            "pin": "required",
            "guest_pin": "required"
        }
        """.data(using: .utf8)

        let error = try decoder.decode(
            TokenError.self,
            from: try XCTUnwrap(data)
        )

        XCTAssertEqual(error, .pinRequired(guestPin: true))
    }

    func testDecodingPinRequiredWithOptionalPin() throws {
        let data = """
        {
            "pin": "required",
            "guest_pin": "none"
        }
        """.data(using: .utf8)

        let error = try decoder.decode(
            TokenError.self,
            from: try XCTUnwrap(data)
        )

        XCTAssertEqual(error, .pinRequired(guestPin: false))
    }

    func testDecodingConferenceExtensionRequired() throws {
        let data = """
        {
            "conference_extension": "standard"
        }
        """.data(using: .utf8)

        let error = try decoder.decode(
            TokenError.self,
            from: try XCTUnwrap(data)
        )

        XCTAssertEqual(error, .conferenceExtensionRequired("standard"))
    }

    func testDecodingSSOIdentityProviderRequired() throws {
        let uuid1 = UUID().uuidString.lowercased()
        let uuid2 = UUID().uuidString.lowercased()
        let data = """
        {
            "idp": [
                {
                    "name": "IDP1",
                    "uuid": "\(uuid1)"
                },
                {
                    "name": "IDP2",
                    "uuid": "\(uuid2)"
                }
            ]
        }
        """.data(using: .utf8)

        let error = try decoder.decode(
            TokenError.self,
            from: try XCTUnwrap(data)
        )

        XCTAssertEqual(
            error,
            .ssoIdentityProviderRequired([
                .init(name: "IDP1", id: uuid1),
                .init(name: "IDP2", id: uuid2)
            ])
        )
    }

    func testDecodingSSOIdentityProviderRedirect() throws {
        let uuid = UUID().uuidString.lowercased()
        let data = """
        {
            "redirect_url": "https://example.com?idp=test",
            "redirect_idp": {
                "name": "IDP1",
                "uuid": "\(uuid)"
            }
        }
        """.data(using: .utf8)

        let error = try decoder.decode(
            TokenError.self,
            from: try XCTUnwrap(data)
        )

        XCTAssertEqual(
            error,
            .ssoIdentityProviderRedirect(
                idp: .init(name: "IDP1", id: uuid),
                url: try XCTUnwrap(URL(string: "https://example.com?idp=test"))
            )
        )
    }

    func testDecodingFailed() throws {
        let data = """
        {
            "field": "value"
        }
        """.data(using: .utf8)

        let error = try decoder.decode(
            TokenError.self,
            from: try XCTUnwrap(data)
        )

        XCTAssertEqual(error, .tokenDecodingFailed)
    }
}
