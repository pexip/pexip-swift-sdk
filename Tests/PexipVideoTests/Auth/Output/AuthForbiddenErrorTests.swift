import XCTest
@testable import PexipVideo

final class AuthForbiddenErrorTests: XCTestCase {
    private let decoder = JSONDecoder()

    // MARK: - Tests

    func testDecodingPinStatusNone() throws {
        let error = try decoder.decode(
            ResponseContainer<AuthForbiddenError>.self,
            from: try jsonData(pin: "none", guestPin: "none")
        ).result

        XCTAssertEqual(error.pinStatus, .none)
        XCTAssertNil(error.conferenceExtension)
    }

    func testDecodingPinStatusMissing() throws {
        let error = try decoder.decode(
            ResponseContainer<AuthForbiddenError>.self,
            from: try jsonData()
        ).result

        XCTAssertEqual(error.pinStatus, .none)
        XCTAssertNil(error.conferenceExtension)
    }

    func testDecodingPinStatusOptional() throws {
        let error = try decoder.decode(
            ResponseContainer<AuthForbiddenError>.self,
            from: try jsonData(pin: "required", guestPin: "none")
        ).result

        XCTAssertEqual(error.pinStatus, .optional)
        XCTAssertNil(error.conferenceExtension)
    }

    func testDecodingPinStatusRequired() throws {
        // Guest: required, Host: required
        let errorA = try decoder.decode(
            ResponseContainer<AuthForbiddenError>.self,
            from: try jsonData(pin: "required", guestPin: "required")
        ).result

        XCTAssertEqual(errorA.pinStatus, .required)
        XCTAssertNil(errorA.conferenceExtension)

        // Guest: required, Host: none
        let errorB = try decoder.decode(
            ResponseContainer<AuthForbiddenError>.self,
            from: try jsonData(pin: "none", guestPin: "required")
        ).result

        XCTAssertEqual(errorB.pinStatus, .required)
        XCTAssertNil(errorB.conferenceExtension)
    }

    func testDecodingConferenceExtensionStandard() throws {
        let error = try decoder.decode(
            ResponseContainer<AuthForbiddenError>.self,
            from: try jsonData(conferenceExtension: "standard")
        ).result

        XCTAssertEqual(error.pinStatus, .none)
        XCTAssertEqual(error.conferenceExtension, .standard)
    }

    func testDecodingConferenceExtensionMssip() throws {
        let error = try decoder.decode(
            ResponseContainer<AuthForbiddenError>.self,
            from: try jsonData(conferenceExtension: "mssip")
        ).result

        XCTAssertEqual(error.pinStatus, .none)
        XCTAssertEqual(error.conferenceExtension, .mssip)
    }

    func testDecodingConferenceExtensionUnknown() throws {
        let data = try jsonData(conferenceExtension: "unknown")

        XCTAssertThrowsError(
            try JSONDecoder().decode(ResponseContainer<AuthForbiddenError>.self, from: data)
        ) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - Helper functions

    private func jsonData(
        pin: String? = nil,
        guestPin: String? = nil,
        conferenceExtension: String? = nil
    ) throws -> Data {
        func field(name: String, value: String?) -> String {
            value.map { "\"\(name)\": \"\($0)\"," } ?? ""
        }

        let json = """
        {
            "status": "success",
            "result": {
                \(field(name: "pin", value: pin))
                \(field(name: "guest_pin", value: guestPin))
                \(field(name: "conference_extension", value: conferenceExtension))
            }
        }
        """

        return try XCTUnwrap(json.data(using: .utf8))
    }
}
