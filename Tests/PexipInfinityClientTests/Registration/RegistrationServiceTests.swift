import XCTest
@testable import PexipInfinityClient

final class RegistrationServiceTests: APITestCase {
    private let baseURL = URL(string: "https://example.com/api/registrations")!
    private var service: RegistrationService!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        service = DefaultRegistrationService(baseURL: baseURL, client: client)
    }

    // MARK: - Request token

    func testRequestTokenWith200() async throws {
        let username = "username"
        let password = "password"
        let expectedToken = RegistrationToken.randomToken()
        let data = try JSONEncoder().encode(Container(result: expectedToken))
        let responseJSON = String(data: data, encoding: .utf8)

        try await testJSONRequest(
            withMethod: .POST,
            url: baseURL.appendingPathComponent("request_token"),
            token: nil,
            body: nil,
            responseJSON: responseJSON,
            assertHTTPErrors: false,
            execute: { [weak self] in
                var token = try await service.requestToken(
                    username: username,
                    password: password
                )
                XCTAssertEqual(
                    self?.lastRequest?.value(forHTTPHeaderField: "Authorization"),
                    HTTPHeader.authorization(username: username, password: password).value
                )
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
            _ = try await service.requestToken(
                username: "username",
                password: "password"
            )
        } catch {
            // 3. Assert error
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testRequestTokenWithUnacceptableStatusCode() async throws {
        // 1. Mock response
        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 503, data: Data(), headers: nil)
        }

        do {
            // 2. Make request
            _ = try await service.requestToken(
                username: "username",
                password: "password"
            )
        } catch {
            // 3. Assert error
            XCTAssertEqual(error as? HTTPError, .unacceptableStatusCode(503))
        }
    }

    // MARK: - Refresh token

    func testRefreshToken() async throws {
        let currentToken = RegistrationToken.randomToken()
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
        let currentToken = RegistrationToken.randomToken()
        let data = try JSONEncoder().encode(Container(result: true))
        let responseJSON = String(data: data, encoding: .utf8)

        try await testJSONRequest(
            withMethod: .POST,
            url: baseURL.appendingPathComponent("release_token"),
            token: currentToken,
            body: nil,
            responseJSON: responseJSON,
            execute: {
                let result = try await service.releaseToken(currentToken)
                XCTAssertTrue(result)
            }
        )
    }
}

// MARK: - Private types

private struct Container<T>: Codable, Hashable where T: Codable, T: Hashable {
    let result: T
}
