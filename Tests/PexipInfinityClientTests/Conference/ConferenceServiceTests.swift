import XCTest
@testable import PexipInfinityClient

final class ConferenceServiceTests: XCTestCase {
    private let baseURL = URL(string: "https://example.com/api/conference/name")!
    private var service: ConferenceService!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolMock.self]

        service = DefaultConferenceService(
            baseURL: baseURL,
            client: HTTPClient(session: URLSession(configuration: configuration))
        )
    }

    // MARK: - Request token

    // swiftlint:disable function_body_length
    func testRequestTokenWith200() async throws {
        let expectedToken = Token.randomToken()
        let data = try JSONEncoder().encode(Container(result: expectedToken))
        var createdRequest: URLRequest?

        // 1. Mock response
        URLProtocolMock.makeResponse = { request in
            createdRequest = request
            return .http(
                statusCode: 200,
                data: data,
                headers: ["Content-Type": "application/json"]
            )
        }

        // 2. Make request
        let identityProvider = IdentityProvider(name: "Name", id: UUID().uuidString)
        let ssoToken = UUID().uuidString
        let fields = RequestTokenFields(
            displayName: "Guest",
            conferenceExtension: "ext",
            idp: identityProvider,
            ssoToken: ssoToken
        )
        let pin = "1234"
        var token = try await service.requestToken(fields: fields, pin: pin)

        // 3. Assert request
        let expectedURL = baseURL.appendingPathComponent("request_token")
        let parameters = try JSONDecoder().decode(
            [String: String].self,
            from: try XCTUnwrap(createdRequest?.httpBody)
        )

        XCTAssertEqual(createdRequest?.url, expectedURL)
        XCTAssertEqual(createdRequest?.httpMethod, "POST")
        XCTAssertEqual(parameters["display_name"], fields.displayName)
        XCTAssertEqual(parameters["conference_extension"], fields.conferenceExtension)
        XCTAssertEqual(parameters["chosen_idp"], fields.chosenIdpId)
        XCTAssertEqual(parameters["sso_token"], fields.ssoToken)
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "Content-Type"),
            "application/json"
        )
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "User-Agent"),
            HTTPHeader.defaultUserAgent.value
        )
        XCTAssertEqual(createdRequest?.value(forHTTPHeaderField: "pin"), pin)
        XCTAssertNil(createdRequest?.value(forHTTPHeaderField: "token"))

        // 4. Assert result
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

    func testRequestTokenWithDecodingError() async throws {
        // 1. Mock response
        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 200, data: Data(), headers: nil)
        }

        // 2. Make request
        let fields = RequestTokenFields(displayName: "Guest")

        do {
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

        // 2. Make request
        let fields = RequestTokenFields(displayName: "Guest")

        do {
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

        // 2. Make request
        let fields = RequestTokenFields(displayName: "Guest")

        do {
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

        // 2. Make request
        let fields = RequestTokenFields(displayName: "Guest")

        do {
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

        // 2. Make request
        let fields = RequestTokenFields(displayName: "Guest")

        do {
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

        // 2. Make request
        let fields = RequestTokenFields(displayName: "Guest")

        do {
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

        // 2. Make request
        let fields = RequestTokenFields(displayName: "Guest")

        do {
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
        let json = """
        {
            "status": "success",
            "result": {
                "token": "\(newTokenValue)",
                "expires": "240"
            }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        var createdRequest: URLRequest?

        // 1. Mock response
        URLProtocolMock.makeResponse = { request in
            createdRequest = request
            return .http(
                statusCode: 200,
                data: data,
                headers: ["Content-Type": "application/json"]
            )
        }

        // 2. Make request
        let newToken = try await service.refreshToken(currentToken)

        // 3. Assert request
        let expectedURL = baseURL.appendingPathComponent("refresh_token")
        XCTAssertEqual(createdRequest?.url, expectedURL)
        XCTAssertEqual(createdRequest?.httpMethod, "POST")
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "User-Agent"),
            HTTPHeader.defaultUserAgent.value
        )
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "token"),
            currentToken.value
        )

        // 4. Assert result
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

    func testReleaseToken() async throws {
        let currentToken = Token.randomToken()
        var createdRequest: URLRequest?

        // 1. Mock response
        URLProtocolMock.makeResponse = { request in
            createdRequest = request
            return .http(
                statusCode: 200,
                data: Data(),
                headers: ["Content-Type": "application/json"]
            )
        }

        // 2. Make request
        try await service.releaseToken(currentToken)

        // 3. Assert request
        let expectedURL = baseURL.appendingPathComponent("release_token")
        XCTAssertEqual(createdRequest?.url, expectedURL)
        XCTAssertEqual(createdRequest?.httpMethod, "POST")
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "User-Agent"),
            HTTPHeader.defaultUserAgent.value
        )
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "token"),
            currentToken.value
        )
    }

    func testMessage() async throws {
        let token = Token.randomToken()
        let message = "Test message"
        let json = """
        {
            "status": "success",
            "result": true
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        var createdRequest: URLRequest?

        // 1. Mock response
        URLProtocolMock.makeResponse = { request in
            createdRequest = request
            return .http(
                statusCode: 200,
                data: data,
                headers: ["Content-Type": "application/json"]
            )
        }

        // 2. Make request
        let result = try await service.message(message, token: token)

        // 3. Assert request
        let expectedURL = baseURL.appendingPathComponent("message")
        let parameters = try JSONDecoder().decode(
            [String: String].self,
            from: try XCTUnwrap(createdRequest?.httpBody)
        )

        XCTAssertEqual(createdRequest?.url, expectedURL)
        XCTAssertEqual(createdRequest?.httpMethod, "POST")
        XCTAssertEqual(parameters["type"], "text/plain")
        XCTAssertEqual(parameters["payload"], message)
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "User-Agent"),
            HTTPHeader.defaultUserAgent.value
        )
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "token"),
            token.value
        )

        // 4. Assert result
        XCTAssertTrue(result)
    }
}

// MARK: - Private types

private struct Container<T>: Codable, Hashable where T: Codable, T: Hashable {
    let result: T
}
