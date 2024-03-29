//
// Copyright 2022-2023 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import XCTest
@testable import PexipInfinityClient

// swiftlint:disable type_body_length file_length
final class ConferenceServiceTests: APITestCase {
    private let baseURL = URL(string: "https://example.com/api/conference/name")!
    private var service: ConferenceService!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        service = DefaultConferenceService(baseURL: baseURL, client: client)
    }

    // MARK: - Request token

    func testRequestTokenWith200() async throws {
        let identityProvider = IdentityProvider(name: "Name", id: UUID().uuidString)
        let ssoToken = UUID().uuidString
        let fields = ConferenceTokenRequestFields(
            displayName: "Guest",
            conferenceExtension: "ext",
            idp: identityProvider,
            ssoToken: ssoToken
        )
        let pin = "1234"
        let expectedToken = ConferenceToken.randomToken()
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
                guard let self else {
                    XCTFail("Test case was deallocated")
                    return
                }

                var token = try await self.service.requestToken(fields: fields, pin: pin)
                XCTAssertEqual(self.lastRequest?.value(forHTTPHeaderField: "pin"), pin)
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

    func testRequestTokenWithIncomingToken() async throws {
        let fields = ConferenceTokenRequestFields(displayName: "Guest")
        let incomingToken = UUID().uuidString
        let expectedToken = ConferenceToken.randomToken()
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
                guard let self else {
                    XCTFail("Test case was deallocated")
                    return
                }

                var token = try await self.service.requestToken(
                    fields: fields,
                    incomingToken: incomingToken
                )
                XCTAssertEqual(
                    self.lastRequest?.value(forHTTPHeaderField: "token"),
                    incomingToken
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
            let fields = ConferenceTokenRequestFields(displayName: "Guest")
            _ = try await service.requestToken(fields: fields, pin: nil)
        } catch {
            // 3. Assert error
            XCTAssertEqual(error as? ConferenceTokenError, .tokenDecodingFailed)
        }
    }

    func testRequestTokenWith401() async throws {
        // 1. Mock response
        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 401, data: Data(), headers: nil)
        }

        do {
            // 2. Make request
            let fields = ConferenceTokenRequestFields(displayName: "Guest")
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
            let fields = ConferenceTokenRequestFields(displayName: "Guest")
            _ = try await service.requestToken(fields: fields, pin: nil)
        } catch {
            // 3. Assert error
            XCTAssertEqual(error as? ConferenceTokenError, .conferenceExtensionRequired("standard"))
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
            let fields = ConferenceTokenRequestFields(displayName: "Guest")
            _ = try await service.requestToken(fields: fields, pin: nil)
        } catch {
            // 3. Assert error
            XCTAssertEqual(error as? ConferenceTokenError, .pinRequired(guestPin: false))
        }
    }

    func testRequestTokenWith403AndPinRequiredErrorWhenPinIsPresent() async throws {
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
            let fields = ConferenceTokenRequestFields(displayName: "Guest")
            _ = try await service.requestToken(fields: fields, pin: "1234")
        } catch {
            // 3. Assert error
            XCTAssertEqual(error as? ConferenceTokenError, .invalidPin)
        }
    }

    func testRequestTokenWithInvalidPinError() async throws {
        let string = """
        {
            "status": "success",
            "result": "Invalid PIN"
        }
        """
        let data = try XCTUnwrap(string.data(using: .utf8))

        // 1. Mock response
        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 403, data: data, headers: nil)
        }

        do {
            // 2. Make request
            let fields = ConferenceTokenRequestFields(displayName: "Guest")
            _ = try await service.requestToken(fields: fields, pin: "1234")
        } catch {
            // 3. Assert error
            XCTAssertEqual(error as? ConferenceTokenError, .invalidPin)
        }
    }

    func testRequestTokenWith404() async throws {
        // 1. Mock response
        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 404, data: Data(), headers: nil)
        }

        do {
            // 2. Make request
            let fields = ConferenceTokenRequestFields(displayName: "Guest")
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
            let fields = ConferenceTokenRequestFields(displayName: "Guest")
            _ = try await service.requestToken(fields: fields, pin: nil)
        } catch {
            // 3. Assert error
            XCTAssertEqual(error as? HTTPError, .unacceptableStatusCode(503))
        }
    }

    // MARK: - Refresh token

    func testRefreshToken() async throws {
        let currentToken = ConferenceToken.randomToken()
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
                XCTAssertEqual(newToken.token, newTokenValue)
                XCTAssertEqual(newToken.expires, "240")
            }
        )
    }

    func testReleaseToken() async throws {
        let currentToken = ConferenceToken.randomToken()

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
        let token = ConferenceToken.randomToken()
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

    func testSplashScreens() async throws {
        let token = ConferenceToken.randomToken()
        var expectedBackground = SplashScreen.Background(path: "background.jpg")
        expectedBackground.url = URL(
            string: baseURL.absoluteString + "/theme/background.jpg?token=\(token.value)"
        )
        let responseJSON = """
        {
            "status": "success",
            "result": {
                "direct_media_welcome": {
                    "layout_type": "direct_media",
                    "background": {
                        "path": "background.jpg"
                    },
                    "elements": [{
                        "type": "text",
                        "color": 4294967295,
                        "text": "Welcome"
                    }]
                }
            }
        }
        """
        try await testJSONRequest(
            withMethod: .GET,
            url: baseURL.appendingPathComponent("theme/"),
            token: token,
            body: nil,
            responseJSON: responseJSON,
            execute: {
                let result = try await service.splashScreens(token: token)
                let splashScreen = SplashScreen(
                    layoutType: "direct_media",
                    background: expectedBackground,
                    elements: [.init(type: "text", color: 4_294_967_295, text: "Welcome")]
                )
                XCTAssertEqual(result, ["direct_media_welcome": splashScreen])
            }
        )
    }

    func testBackgroundURL() {
        let background = SplashScreen.Background(path: "background.jpg")
        let token = ConferenceToken.randomToken()
        let url = service.backgroundURL(for: background, token: token)

        XCTAssertEqual(
            url?.absoluteString,
            baseURL.absoluteString + "/theme/background.jpg?token=\(token.value)"
        )
    }
}
// swiftlint:enable type_body_length

// MARK: - Private types

private struct Container<T>: Codable, Hashable where T: Codable, T: Hashable {
    let result: T
}

// swiftlint:enable file_length
