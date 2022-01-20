import Foundation

final class ClientControlAPI {
    private let configuration: APIConfiguration
    private let httpClient: HTTPClient
    private let decoder = JSONDecoder()
    
    // MARK: - Init
    
    init(configuration: APIConfiguration, httpClient: HTTPClient = .init()) {
        self.configuration = configuration
        self.httpClient = httpClient
    }
    
    // MARK: - API
    
    /// - Parameters:
    ///   - displayName: The name by which this participant should be known
    ///   - pin: User-supplied PIN (if required)
    ///   - conferenceExtension: Conference to connect to (when being used with a Virtual Reception)
    ///
    /// - Returns: Information about the service you are connecting to
    func requestToken(
        displayName: String,
        pin: String? = nil,
        conferenceExtension: String? = nil
    ) async throws -> Token {
        let url = configuration.url(forRequest: "request_token")
        let headers = pin.map { [HTTPHeader(name: "pin", value: $0)] } ?? []
        let parameters = [
            "display_name": displayName,
            "conference_extension": conferenceExtension
        ]
        
        do {
            let (data, response) = try await httpClient.post(
                url: url,
                parameters: parameters,
                headers: headers
            )
            
            switch response.statusCode {
            case 200:
                return try decoder.decode(ResponseBody<Token>.self, from: data).result
            case 401:
                // Bad HTTP credentials
                throw ClientControlError.authenticationFailed
            case 403:
                // PIN challenge
                do {
                    throw try decoder.decode(ResponseBody<TokenError>.self, from: data).result
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
}

// MARK: - Errors

enum ClientControlError: LocalizedError {
    case authenticationFailed
    case conferenceNotFound
    case connectionFailed(statusCode: Int)
    case invalidPin
    case decodingFailed
    case badServerResponse
}
