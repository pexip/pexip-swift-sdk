import XCTest
@testable import PexipVideo

final class TokenClientTests: APIClientTestCase<TokenClient> {
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
        let identityProvider = IdentityProvider(name: "Name", uuid: UUID().uuidString)
        let ssoToken = UUID().uuidString
        let request = TokenRequest(
            displayName: "Guest",
            pin: "1234",
            conferenceExtension: "ext",
            idp: identityProvider,
            ssoToken: ssoToken
        )
        var token = try await client.requestToken(with: request)

        // 3. Assert request
        let expectedUrlString = "\(nodeAddress)/api/client/v2/conferences/\(alias.uri)/request_token"
        let parameters = try JSONDecoder().decode(
            [String: String].self,
            from: try XCTUnwrap(createdRequest?.httpBody)
        )

        XCTAssertEqual(createdRequest?.url, try XCTUnwrap(URL(string: expectedUrlString)))
        XCTAssertEqual(createdRequest?.httpMethod, "POST")
        XCTAssertEqual(parameters["display_name"], request.displayName)
        XCTAssertEqual(parameters["conference_extension"], request.conferenceExtension)
        XCTAssertEqual(parameters["chosen_idp"], request.idp?.uuid)
        XCTAssertEqual(parameters["sso_token"], request.ssoToken)
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "Content-Type"),
            "application/json"
        )
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "User-Agent"),
            HTTPHeader.defaultUserAgent.value
        )
        XCTAssertEqual(createdRequest?.value(forHTTPHeaderField: "pin"), request.pin)
        XCTAssertNil(createdRequest?.value(forHTTPHeaderField: "token"))

        // 4. Assert result
        XCTAssertEqual(token.value, expectedToken.value)
        XCTAssertEqual(token.expires, expectedToken.expires)
        // Update token to have the same `updatedAt` date as in expected token
        token.update(
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
        let request = TokenRequest(displayName: "Guest")

        do {
            _ = try await client.requestToken(with: request)
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
        let request = TokenRequest(displayName: "Guest")

        do {
            _ = try await client.requestToken(with: request)
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
        let request = TokenRequest(displayName: "Guest")

        do {
            _ = try await client.requestToken(with: request)
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
        let request = TokenRequest(displayName: "Guest")

        do {
            _ = try await client.requestToken(with: request)
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
        let request = TokenRequest(displayName: "Guest", pin: "1234")

        do {
            _ = try await client.requestToken(with: request)
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
        let request = TokenRequest(displayName: "Guest")

        do {
            _ = try await client.requestToken(with: request)
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
        let request = TokenRequest(displayName: "Guest")

        do {
            _ = try await client.requestToken(with: request)
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
        let newToken = try await client.refreshToken(currentToken)

        // 3. Assert request
        let expectedUrlString = "\(nodeAddress)/api/client/v2/conferences/\(alias.uri)/refresh_token"
        XCTAssertEqual(createdRequest?.url, try XCTUnwrap(URL(string: expectedUrlString)))
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
        expectedToken.update(
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
        try await client.releaseToken(currentToken)

        // 3. Assert request
        let expectedUrlString = "\(nodeAddress)/api/client/v2/conferences/\(alias.uri)/release_token"
        XCTAssertEqual(createdRequest?.url, try XCTUnwrap(URL(string: expectedUrlString)))
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
}

// MARK: - Private types

private struct Container<T>: Codable, Hashable where T: Codable, T: Hashable {
    let result: T
}
