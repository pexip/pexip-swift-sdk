import Foundation
import PexipUtils

// MARK: - Protocols

/// Represents the token requests from the [Conference control functions](https://docs.pexip.com/api_client/api_rest.htm?Highlight=api#conference) section.
public protocol TokenService {
    /**
     Requests a new token from the Pexip Conferencing Node.
     See [documentation](https://docs.pexip.com/api_client/api_rest.htm?Highlight=api#request_token)

     - Parameters:
        - fields: Request fields
        - pin An optional PIN
     - Returns: A token of the conference
     - Throws: `TokenError` if "403 Forbidden" is returned. See `TokenError` for more details.
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func requestToken(
        fields: RequestTokenFields,
        pin: String?
    ) async throws -> Token

    /**
     Refreshes a token to get a new one.
     See [documentation](https://docs.pexip.com/api_client/api_rest.htm?Highlight=api#refresh_token)

     - Parameter token: Current valid API token
     - Returns: New API token
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func refreshToken(_ token: Token) async throws -> Token

    /**
     Releases the token (effectively a disconnect for the participant).
     See [documentation](https://docs.pexip.com/api_client/api_rest.htm?Highlight=api#release_token)

     - Parameter token: Current valid API token
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func releaseToken(_ token: Token) async throws
}

/// Represents the [Conference control functions](https://docs.pexip.com/api_client/api_rest.htm?Highlight=api#conference) section.
public protocol ConferenceService: TokenService {
    /**
     Sends a message to all participants in the conference.
     - Parameters:
        - message: Text message
        - token: Current valid API token
     - Returns: The result is true if successful, false otherwise.
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func message(_ message: String, token: Token) async throws -> Bool

    /// HTTP EventSource which feeds events from the conference as they occur.
    func eventSource() -> ServerEventService

    /**
     Sets the participant ID.
     - Parameters:
        - id: The ID of the participant
     - Returns: A new instance of ``ParticipantStep``
     */
    func participant(id: UUID) -> ParticipantService
}

// MARK: - Implementation

struct DefaultConferenceService: ConferenceService {
    let baseURL: URL
    let client: HTTPClient
    var decoder = JSONDecoder()
    var logger: Logger?

    func requestToken(
        fields: RequestTokenFields,
        pin: String?
    ) async throws -> Token {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("request_token"),
            httpMethod: .POST
        )
        try request.setJSONBody(fields)
        let pin = (pin?.isEmpty == true ? "none" : pin)

        if let pin = pin {
            request.setHTTPHeader(.init(name: "pin", value: pin))
        }

        do {
            let (data, response) = try await client.data(for: request, validate: false)

            switch response.statusCode {
            case 200:
                return try parse200(from: data)
            case 401:
                // Bad HTTP credentials
                throw HTTPError.unauthorized
            case 403:
                throw try parse403Error(from: data, pin: pin)
            case 404:
                throw HTTPError.resourceNotFound("conference")
            default:
                throw HTTPError.unacceptableStatusCode(response.statusCode)
            }
        } catch is DecodingError {
            throw TokenError.tokenDecodingFailed
        } catch {
            throw error
        }
    }

    func refreshToken(_ token: Token) async throws -> Token {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("refresh_token"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        let newToken: NewToken = try await client.json(for: request)
        return token.updating(value: newToken.token, expires: newToken.expires)
    }

    func releaseToken(_ token: Token) async throws {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("release_token"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        _ = try await client.data(for: request)
    }

    func message(_ message: String, token: Token) async throws -> Bool {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("message"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        try request.setJSONBody([
            "type": "text/plain",
            "payload": message
        ])
        return try await client.json(for: request)
    }

    func eventSource() -> ServerEventService {
        return DefaultServerEventService(
            baseURL: baseURL,
            client: client,
            decoder: decoder,
            logger: logger
        )
    }

    func participant(id: UUID) -> ParticipantService {
        let url = baseURL
            .appendingPathComponent("participants")
            .appendingPathComponent(id.uuidString.lowercased())
        return DefaultParticipantService(baseURL: url, client: client)
    }

    // MARK: - Private methods

    private func parse200(from data: Data) throws -> Token {
        try decoder.decode(
            ResponseContainer<Token>.self,
            from: data
        ).result
    }

    private func parse403Error(from data: Data, pin: String?) throws -> Error {
        let error = try decoder.decode(
            ResponseContainer<TokenError>.self,
            from: data
        ).result

        switch error {
        case .pinRequired:
            return pin != nil ? TokenError.invalidPin : error
        default:
            return error
        }
    }
}

// MARK: - Private types

private struct NewToken: Decodable, Hashable {
    let token: String
    let expires: String
}
