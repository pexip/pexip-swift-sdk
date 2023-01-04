import Foundation
import PexipCore

// MARK: - Protocols

// swiftlint:disable line_length

/// Represents the [Conference control functions](https://docs.pexip.com/api_client/api_rest.htm?Highlight=api#conference) section.
public protocol ConferenceService: TokenService, ChatService, SplashScreenService {
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
        fields: ConferenceTokenRequestFields,
        pin: String?
    ) async throws -> ConferenceToken

    /**
     Requests a new token from the Pexip Conferencing Node
     using the given incoming registration token.
     See [documentation](https://docs.pexip.com/api_client/api_rest.htm?Highlight=api#request_token)

     - Parameters:
        - fields: Request fields
        - incomingToken The incoming registration token
     - Returns: A token of the conference
     - Throws: `TokenError` if "403 Forbidden" is returned. See `TokenError` for more details.
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func requestToken(
        fields: ConferenceTokenRequestFields,
        incomingToken: String
    ) async throws -> ConferenceToken

    /// HTTP EventSource which feeds events from the conference as they occur.
    func eventSource() -> ConferenceEventService

    /**
     Sets the participant ID.
     - Parameters:
        - id: The ID of the participant
     - Returns: A new instance of ``ParticipantService``
     */
    func participant(id: String) -> ParticipantService
}

// MARK: - Implementation

struct DefaultConferenceService: ConferenceService {
    let baseURL: URL
    let client: HTTPClient
    var decoder = JSONDecoder()
    var logger: Logger?

    func requestToken(
        fields: ConferenceTokenRequestFields,
        pin: String?
    ) async throws -> ConferenceToken {
        try await requestToken(fields: fields, pin: pin, incomingToken: nil)
    }

    func requestToken(
        fields: ConferenceTokenRequestFields,
        incomingToken: String
    ) async throws -> ConferenceToken {
        try await requestToken(fields: fields, pin: nil, incomingToken: incomingToken)
    }

    func refreshToken(_ token: InfinityToken) async throws -> TokenRefreshResponse {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("refresh_token"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        return try await client.json(for: request)
    }

    func releaseToken(_ token: InfinityToken) async throws {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("release_token"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        _ = try await client.data(for: request)
    }

    func message(_ message: String, token: ConferenceToken) async throws -> Bool {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("message"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        try request.setJSONBody(MessageFields(payload: message))
        return try await client.json(for: request)
    }

    func eventSource() -> ConferenceEventService {
        DefaultConferenceEventService(
            baseURL: baseURL,
            client: client,
            decoder: decoder,
            logger: logger
        )
    }

    func participant(id: String) -> ParticipantService {
        let url = baseURL
            .appendingPathComponent("participants")
            .appendingPathComponent(id)
        return DefaultParticipantService(baseURL: url, client: client)
    }

    func splashScreens(token: ConferenceToken) async throws -> [String: SplashScreen] {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("theme/"),
            httpMethod: .GET
        )
        request.setHTTPHeader(.token(token.value))
        var splashScreens: [String: SplashScreen] = try await client.json(for: request)

        for key in splashScreens.keys {
            if let background = splashScreens[key]?.background {
                splashScreens[key]?.background.url = backgroundURL(for: background, token: token)
            }
        }

        return splashScreens
    }

    func backgroundURL(
        for background: SplashScreen.Background,
        token: ConferenceToken
    ) -> URL? {
        var components = URLComponents(
            url: baseURL
                .appendingPathComponent("theme")
                .appendingPathComponent(background.path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "token", value: token.value)
        ]
        return components?.url
    }

    // MARK: - Private methods

    private func requestToken(
        fields: ConferenceTokenRequestFields,
        pin: String?,
        incomingToken: String?
    ) async throws -> ConferenceToken {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("request_token"),
            httpMethod: .POST
        )
        try request.setJSONBody(fields)
        let pin = (pin?.isEmpty == true ? "none" : pin)

        if let pin {
            request.setHTTPHeader(.init(name: "pin", value: pin))
        }

        if let incomingToken {
            request.setHTTPHeader(.token(incomingToken))
        }

        do {
            let (data, response) = try await client.data(
                for: request,
                validate: false
            )

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
            throw ConferenceTokenError.tokenDecodingFailed
        } catch {
            throw error
        }
    }

    private func parse200(from data: Data) throws -> ConferenceToken {
        try decoder.decode(
            ResponseContainer<ConferenceToken>.self,
            from: data
        ).result
    }

    private func parse403Error(from data: Data, pin: String?) throws -> Error {
        let error = try decoder.decode(
            ResponseContainer<ConferenceTokenError>.self,
            from: data
        ).result

        switch error {
        case .pinRequired:
            return pin != nil ? ConferenceTokenError.invalidPin : error
        default:
            return error
        }
    }
}
