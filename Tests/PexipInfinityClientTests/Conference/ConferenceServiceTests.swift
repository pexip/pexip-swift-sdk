import XCTest
@testable import PexipInfinityClient

final class ConferenceServiceTests: APITestCase {
    private let baseURL = URL(string: "https://example.com/api/conference/name")!
    private var service: ConferenceService!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        service = DefaultConferenceService(baseURL: baseURL, client: client)
    }

    // MARK: - Request token

    // swiftlint:disable function_body_length
    func testRequestTokenWith200() async throws {
        let identityProvider = IdentityProvider(name: "Name", id: UUID().uuidString)
        let ssoToken = UUID().uuidString
        let fields = RequestTokenFields(
            displayName: "Guest",
            conferenceExtension: "ext",
            idp: identityProvider,
            ssoToken: ssoToken
        )
        let pin = "1234"
        let expectedToken = Token.randomToken()
        let data = try JSONEncoder().encode(Container(result: expectedToken))
        let responseJSON = String(data: data, encoding: .utf8)

        try await testJSONRequest(
            withMethod: .POST,
            url: baseURL.appendingPathComponent("request_token"),
            token: nil,
            body: try JSONEncoder().encode(fields),
            responseJSON: responseJSON,
            assertHTTPErrors: false,
            execute: { [weak self] in
                var token = try await service.requestToken(fields: fields, pin: pin)
                XCTAssertEqual(self?.lastRequest?.value(forHTTPHeaderField: "pin"), pin)
                XCTAssertEqual(token.value, expectedToken.value)
                XCTAssertEqual(token.expires, expectedToken.expires)
                // Update token to have the same `updatedAt` date as in expected token
                token = token.updating(
                    value: expectedToken.value,
                    expires: "\(expectedToken.expires)",
                    updatedAt: expectedToken.updatedAt
                )
                XCTAssertEqual(token, expectedToken)
            }
        )
    }

    func testRequestTokenWithDecodingError() async throws {
        // 1. Mock response
        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 200, data: Data(), headers: nil)
        }

        do {
            // 2. Make request
            let fields = RequestTokenFields(displayName: "Guest")
            _ = try await service.requestToken(fields: fields, pin: nil)
        } catch {
            // 3. Assert error
            XCTAssertEqual(error as? TokenError, .tokenDecodingFailed)
        }
    }

    func testRequestTokenWith401() async throws {
        // 1. Mock response
        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 401, data: Data(), headers: nil)
        }

        do {
            // 2. Make request
            let fields = RequestTokenFields(displayName: "Guest")
            _ = try await service.requestToken(fields: fields, pin: nil)
        } catch {
            // 3. Assert error
            XCTAssertEqual(error as? HTTPError, .unauthorized)
        }
    }

    func testRequestTokenWith403AndConferenceExtensionError() async throws {
        let string = """
        {
            "status": "success",
            "result": {
                "conference_extension": "standard"
            }
        }
        """
        let data = try XCTUnwrap(string.data(using: .utf8))

        // 1. Mock response
        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 403, data: data, headers: nil)
        }

        do {
            // 2. Make request
            let fields = RequestTokenFields(displayName: "Guest")
            _ = try await service.requestToken(fields: fields, pin: nil)
        } catch {
            // 3. Assert error
            XCTAssertEqual(error as? TokenError, .conferenceExtensionRequired("standard"))
        }
    }

    func testRequestTokenWith403AndPinRequiredError() async throws {
        let string = """
        {
            "status": "success",
            "result": {
                "pin": "required",
                "guest_pin": "none"
            }
        }
        """
        let data = try XCTUnwrap(string.data(using: .utf8))

        // 1. Mock response
        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 403, data: data, headers: nil)
        }

        do {
            // 2. Make request
            let fields = RequestTokenFields(displayName: "Guest")
            _ = try await service.requestToken(fields: fields, pin: nil)
        } catch {
            // 3. Assert error
            XCTAssertEqual(error as? TokenError, .pinRequired(guestPin: false))
        }
    }

    func testRequestTokenWith403AndInvalidPinError() async throws {
        let string = """
        {
            "status": "success",
            "result": {
                "pin": "required",
                "guest_pin": "none"
            }
        }
        """
        let data = try XCTUnwrap(string.data(using: .utf8))

        // 1. Mock response
        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 403, data: data, headers: nil)
        }

        do {
            // 2. Make request
            let fields = RequestTokenFields(displayName: "Guest")
            _ = try await service.requestToken(fields: fields, pin: "1234")
        } catch {
            // 3. Assert error
            XCTAssertEqual(error as? TokenError, .invalidPin)
        }
    }

    func testRequestTokenWith404() async throws {
        // 1. Mock response
        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 404, data: Data(), headers: nil)
        }

        do {
            // 2. Make request
            let fields = RequestTokenFields(displayName: "Guest")
            _ = try await service.requestToken(fields: fields, pin: nil)
        } catch {
            // 3. Assert error
            XCTAssertEqual(error as? HTTPError, .resourceNotFound("conference"))
        }
    }

    func testRequestTokenWithUnacceptableStatusCode() async throws {
        // 1. Mock response
        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 503, data: Data(), headers: nil)
        }

        do {
            // 2. Make request
            let fields = RequestTokenFields(displayName: "Guest")
            _ = try await service.requestToken(fields: fields, pin: nil)
        } catch {
            // 3. Assert error
            XCTAssertEqual(error as? HTTPError, .unacceptableStatusCode(503))
        }
    }

    // MARK: - Refresh token

    func testRefreshToken() async throws {
        let currentToken = Token.randomToken()
        let newTokenValue = UUID().uuidString
        let responseJSON = """
        {
            "status": "success",
            "result": {
                "token": "\(newTokenValue)",
                "expires": "240"
            }
        }
        """

        try await testJSONRequest(
            withMethod: .POST,
            url: baseURL.appendingPathComponent("refresh_token"),
            token: currentToken,
            body: nil,
            responseJSON: responseJSON,
            execute: {
                let newToken = try await service.refreshToken(currentToken)
                XCTAssertEqual(newToken.value, newTokenValue)
                XCTAssertEqual(newToken.expires, 240)
                XCTAssertTrue(newToken.updatedAt > currentToken.updatedAt)

                var expectedToken = currentToken
                expectedToken = expectedToken.updating(
                    value: newTokenValue,
                    expires: "240",
                    updatedAt: newToken.updatedAt
                )
                XCTAssertEqual(newToken, expectedToken)
            }
        )
    }

    func testReleaseToken() async throws {
        let currentToken = Token.randomToken()

        try await testJSONRequest(
            withMethod: .POST,
            url: baseURL.appendingPathComponent("release_token"),
            token: currentToken,
            body: nil,
            responseJSON: nil,
            execute: {
                try await service.releaseToken(currentToken)
            }
        )
    }

    func testMessage() async throws {
        let token = Token.randomToken()
        let message = "Test message"
        let responseJSON = """
        {
            "status": "success",
            "result": true
        }
        """
        try await testJSONRequest(
            withMethod: .POST,
            url: baseURL.appendingPathComponent("message"),
            token: token,
            body: try JSONEncoder().encode(MessageFields(payload: message)),
            responseJSON: responseJSON,
            execute: {
                let result = try await service.message(message, token: token)
                XCTAssertTrue(result)
            }
        )
    }
}

// MARK: - Private types

private struct Container<T>: Codable, Hashable where T: Codable, T: Hashable {
    let result: T
}
