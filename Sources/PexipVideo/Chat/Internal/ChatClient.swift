import Foundation

// MARK: - Protocols

/// Pexip client REST API v2.
protocol ChatClientProtocol {
    /**
     Sends a message to all participants in the conference.
     - Parameter message: Text message
     - Returns: The result is true if successful, false otherwise.
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func sendChatMessage(_ message: String) async throws -> Bool
}

// MARK: - Implementation

extension InfinityClient: ChatClientProtocol {
    func sendChatMessage(_ message: String) async throws -> Bool {
        var request = try await request(
            withMethod: .POST,
            path: .conference,
            name: "message"
        )
        try request.setJSONBody([
            "type": "text/plain",
            "payload": message
        ])
        return try await json(for: request)
    }
}
