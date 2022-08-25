import Foundation
import PexipUtils

// MARK: - Protocols

/// Represents the registration control functions section.
public protocol RegistrationService {
    /**
     Requests a token for the registration alias.

     - Parameters:
        - username: A username
        - password: A password
     - Returns: A registration token
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func requestToken(username: String, password: String) async throws -> RegistrationToken

    /**
     Refreshes the token to get a new one.

     - Parameters:
        - token: Current valid registration token
     - Returns: New registration token
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func refreshToken(_ token: RegistrationToken) async throws -> RegistrationToken

    /**
     Releases the token.
     - Parameters:
        - token: Current valid registration token
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func releaseToken(_ token: RegistrationToken) async throws -> Bool

    /// HTTP EventSource which feeds server sent events as they occur.
    func eventSource() -> RegistrationEventService
}

// MARK: - Implementation

struct DefaultRegistrationService: RegistrationService {
    let baseURL: URL
    let client: HTTPClient
    var decoder = JSONDecoder()
    var logger: Logger?

    func requestToken(username: String, password: String) async throws -> RegistrationToken {
        guard !username.isEmpty, !password.isEmpty else {
            throw ValidationError.invalidArgument
        }

        var request = URLRequest(
            url: baseURL.appendingPathComponent("request_token"),
            httpMethod: .POST
        )

        request.setHTTPHeader(.authorization(username: username, password: password))

        return try await client.json(for: request)
    }

    func refreshToken(_ token: RegistrationToken) async throws -> RegistrationToken {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("refresh_token"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        let newToken: NewToken = try await client.json(for: request)
        return token.updating(value: newToken.token, expires: newToken.expires)
    }

    func releaseToken(_ token: RegistrationToken) async throws -> Bool {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("release_token"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        return try await client.json(for: request)
    }

    func eventSource() -> RegistrationEventService {
        DefaultRegistrationEventService(
            baseURL: baseURL,
            client: client,
            decoder: decoder,
            logger: logger
        )
    }
}

// MARK: - Private types

private struct NewToken: Decodable, Hashable {
    let token: String
    let expires: String
}
