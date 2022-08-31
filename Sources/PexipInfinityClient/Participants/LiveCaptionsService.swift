import Foundation

// MARK: - Protocol

public protocol LiveCaptionsService {
    /**
     Starts receiving live caption events.

     - Parameters:
        - token: Current valid API token
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func showLiveCaptions(token: ConferenceToken) async throws

    /**
     Stop receiving live caption events.

     - Parameters:
        - token: Current valid API token
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func hideLiveCaptions(token: ConferenceToken) async throws
}

// MARK: - Extensions

public extension LiveCaptionsService {
    /**
     Toggle live caption events.

     - Parameters:
        - enabled: Boolean indicating whether the live captions are enabled or not.
        - token: Current valid API token

     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func toggleLiveCaptions(_ enabled: Bool, token: ConferenceToken) async throws {
        if enabled {
            try await showLiveCaptions(token: token)
        } else {
            try await hideLiveCaptions(token: token)
        }
    }
}
