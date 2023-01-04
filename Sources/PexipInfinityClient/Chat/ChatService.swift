import Foundation

/// Conference chat message service.
public protocol ChatService {
    /**
     Sends a message to all participants in the conference.

     - Parameters:
        - message: Text message
        - token: Current valid API token
     - Returns: The result is true if successful, false otherwise.
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func message(_ message: String, token: ConferenceToken) async throws -> Bool
}
