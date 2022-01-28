import Foundation

// MARK: - Protocol

protocol AuthClientProtocol {
    /// Requests a new token from the Pexip Conferencing Node.
    ///
    /// - Parameters:
    ///   - displayName: The name by which this participant should be known
    ///   - pin: User-supplied PIN (if required)
    ///   - conferenceExtension: Conference to connect to (when being used with a Virtual Reception)
    ///
    /// - Returns: Information about the service you are connecting to
    func requestToken(
        displayName: String,
        pin: String?,
        conferenceExtension: String?
    ) async throws -> (AuthToken, ConnectionDetails)
    
    /// Refreshes a token to get a new one.
    ///
    /// - Returns: New authentication token
    func refreshToken() async throws -> AuthToken
    
    /// Releases the token (effectively a disconnect for the participant).
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
                throw ClientControlError.authenticationFailed
            case 403:
                // PIN challenge
                do {
                    throw try decoder.decode(ResponseContainer<ConnectionError>.self, from: data).result
                } catch is DecodingError {
                    // Not able to parse requirements for `requestToken` request, PIN challenge failed
                    throw ClientControlError.invalidPin
                } catch {
                    throw error
                }
            case 404:
                throw ClientControlError.conferenceNotFound
            default:
                throw ClientControlError.connectionFailed(statusCode: response.statusCode)
            }
        } catch is DecodingError {
            throw ClientControlError.decodingFailed
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

enum ClientControlError: LocalizedError {
    case authenticationFailed
    case conferenceNotFound
    case connectionFailed(statusCode: Int)
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
