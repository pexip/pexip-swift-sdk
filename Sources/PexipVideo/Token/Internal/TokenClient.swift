import Foundation

// MARK: - Protocols

typealias TokenClient = TokenRequesterProtocol & TokenManagerClientProtocol

/// Pexip client REST API v2.
protocol TokenManagerClientProtocol {
    /**
     Refreshes a token to get a new one.
     - Parameter token: Current API token
     - Returns: New API token
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func refreshToken(_ token: Token) async throws -> Token

    /**
     Releases the token (effectively a disconnect for the participant).
     - Parameter token: Current API token
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func releaseToken(_ token: Token) async throws
}

// MARK: - Implementation

extension InfinityClient: TokenRequesterProtocol {
    func requestToken(with parameters: TokenRequest) async throws -> Token {
        var request = try await request(
            withMethod: .POST,
            path: .conference,
            name: "request_token",
            token: .empty
        )

        try request.setJSONBody([
            "display_name": parameters.displayName,
            "conference_extension": parameters.conferenceExtension,
            "chosen_idp": parameters.idp?.uuid,
            "sso_token": parameters.ssoToken
        ].compactMapValues({ $0 }))

        if let pin = parameters.pin {
            request.setHTTPHeader(.init(name: "pin", value: pin))
        }

        do {
            logger[.auth].debug("Requesting a new token from the Pexip Conferencing Node...")

            let (data, response) = try await data(for: request, validate: false)

            switch response.statusCode {
            case 200:
                return try parse200(from: data)
            case 401:
                // Bad HTTP credentials
                throw HTTPError.unauthorized
            case 403:
                throw try parse403Error(from: data, pin: parameters.pin)
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

extension InfinityClient: TokenManagerClientProtocol {
    func refreshToken(_ token: Token) async throws -> Token {
        let request = try await request(
            withMethod: .POST,
            path: .conference,
            name: "refresh_token",
            token: .value(token)
        )
        let newToken: NewToken = try await json(for: request)
        var token = token

        token.update(value: newToken.token, expires: newToken.expires)

        return token
    }

    func releaseToken(_ token: Token) async throws {
        let request = try await request(
            withMethod: .POST,
            path: .conference,
            name: "release_token",
            token: .value(token)
        )
        _ = try await data(for: request)
    }
}

// MARK: - Private types

private struct NewToken: Decodable, Hashable {
    let token: String
    let expires: String
}
