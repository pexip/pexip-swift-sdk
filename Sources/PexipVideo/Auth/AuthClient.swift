import Foundation

// MARK: - Protocol

/// Pexip client REST API v2.
protocol AuthClientProtocol {
    /// Requests a new token from the Pexip Conferencing Node.
    ///
    /// - Parameters:
    ///   - displayName: The name by which this participant should be known
    ///   - pin: User-supplied PIN (if required)
    ///   - conferenceExtension: Conference to connect to (when being used with a Virtual Reception)
    ///
    /// - Returns: Information about the service you are connecting to
    /// - Throws: `AuthForbiddenError` if either host/guest PIN or `conferenceExtension` is required
    /// - Throws: `AuthError.invalidPin` if the supplied `pin` is invalid
    /// - Throws: `AuthError.decodingFailed` if JSON decoding failed
    /// - Throws: `HTTPError` if a network error was encountered during operation
    func requestToken(
        displayName: String,
        pin: String?,
        conferenceExtension: String?
    ) async throws -> (AuthToken, ConnectionDetails)
    
    /// Refreshes a token to get a new one.
    ///
    /// - Returns: New authentication token
    /// - Throws: `HTTPError` if a network error was encountered during operation
    func refreshToken() async throws -> AuthToken
    
    /// Releases the token (effectively a disconnect for the participant).
    /// - Throws: `HTTPError` if a network error was encountered during operation
    func releaseToken() async throws
}

// MARK: - Implementation

struct AuthClient: AuthClientProtocol {
    private let urlSession: URLSession
    private let requestFactory: HTTPRequestFactory
    private let decoder = JSONDecoder()
    
    // MARK: - Init
    
    init(
        apiConfiguration: APIConfiguration,
        urlSession: URLSession,
        authStorage: AuthStorage
    ) {
        self.urlSession = urlSession
        self.requestFactory = HTTPRequestFactory(
            baseURL: apiConfiguration.conferenceBaseURL,
            authTokenProvider: authStorage
        )
    }
    
    // MARK: - API
    
    func requestToken(
        displayName: String,
        pin: String? = nil,
        conferenceExtension: String? = nil
    ) async throws -> (AuthToken, ConnectionDetails) {
        var request = try await requestFactory.request(withName: "request_token", method: .POST)
        
        try request.setJSONBody([
            "display_name": displayName,
            "conference_extension": conferenceExtension
        ])
        
        if let pin = pin {
            request.setHTTPHeader(.init(name: "pin", value: pin))
        }
        
        do {
            let (data, response) = try await urlSession.http.data(for: request, validate: false)
            
            switch response.statusCode {
            case 200:
                let container = try decoder.decode(
                    ResponseContainer<TokenResponse>.self,
                    from: data
                )
                return (container.result.authToken, container.result.connectionDetails)
            case 401:
                // Bad HTTP credentials
                throw HTTPError.unauthorized
            case 403:
                // PIN challenge
                do {
                    throw try decoder.decode(ResponseContainer<AuthForbiddenError>.self, from: data).result
                } catch is DecodingError {
                    // Not able to parse requirements for `requestToken` request, PIN challenge failed
                    throw AuthError.invalidPin
                } catch {
                    throw error
                }
            case 404:
                throw HTTPError.resourceNotFound("conference")
            default:
                throw HTTPError.unacceptableStatusCode(response.statusCode)
            }
        } catch is DecodingError {
            throw AuthError.decodingFailed
        } catch {
            throw error
        }
    }

    func refreshToken() async throws -> AuthToken {
        let request = try await requestFactory.request(withName: "refresh_token", method: .POST)
        return try await urlSession.http.json(for: request, decoder: decoder)
    }
    
    func releaseToken() async throws {
        let request = try await requestFactory.request(withName: "release_token", method: .POST)
        _ = try await urlSession.http.data(for: request)
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case invalidPin
    case decodingFailed
}

// MARK: - Private types

private struct TokenResponse: Decodable, Hashable {
    let authToken: AuthToken
    let connectionDetails: ConnectionDetails

    init(from decoder: Decoder) throws {
        authToken = try AuthToken(from: decoder)
        connectionDetails = try ConnectionDetails(from: decoder)
    }
}
