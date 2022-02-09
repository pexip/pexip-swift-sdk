import Foundation

// MARK: - Protocol

/// Pexip client REST API v2.
protocol CallClientProtocol {
    /// Starts media for the specified call (WebRTC calls only).
    ///
    /// - Returns: The result is true if successful, false otherwise.
    /// - Throws: `HTTPError` if a network error was encountered during operation
    func ack() async throws -> Bool

    /// Disconnects the specified call.
    ///
    /// - Returns: The result is true if successful, false otherwise.
    /// - Throws: `HTTPError` if a network error was encountered during operation
    func disconnect() async throws -> Bool
}

// MARK: - Implementation

struct CallClient: CallClientProtocol {
    private let httpSession: HTTPSession
    private let requestFactory: HTTPRequestFactory
    private let decoder = JSONDecoder()

    // MARK: - Init

    init(
        participantUUID: UUID,
        callUUID: UUID,
        apiConfiguration: APIConfiguration,
        httpSession: HTTPSession,
        authTokenProvider: AuthTokenProvider
    ) {
        self.httpSession = httpSession
        self.requestFactory = HTTPRequestFactory(
            baseURL: apiConfiguration.callBaseURL(
                participantUUID: participantUUID,
                callUUID: callUUID
            ),
            authTokenProvider: authTokenProvider
        )
    }

    // MARK: - API

    func ack() async throws -> Bool {
        let request = try await requestFactory.request(withName: "ack", method: .POST)
        return try await httpSession.json(for: request, decoder: decoder)
    }

    func disconnect() async throws -> Bool {
        let request = try await requestFactory.request(withName: "disconnect", method: .POST)
        return try await httpSession.json(for: request, decoder: decoder)
    }
}
