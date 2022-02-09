import Foundation

// MARK: - Protocol

/// Pexip client REST API v2.
protocol ParticipantClientProtocol {
    /// Upgrades this connection to have an audio/video call element.
    ///
    /// - Parameters:
    ///   - sdp: Contains the SDP of the sender
    ///   - present: Optional field. Contains "send" or "receive"
    ///              to act as a presentation stream rather than a main audio/video stream.
    /// - Returns: Information about the service you are connecting to
    /// - Throws: `HTTPError` if a network error was encountered during operation
    func makeCall(sdp: String, present: String?) async throws -> Call
}

// MARK: - Implementation

struct ParticipantClient: ParticipantClientProtocol {
    private let httpSession: HTTPSession
    private let requestFactory: HTTPRequestFactory
    private let decoder = JSONDecoder()

    // MARK: - Init

    init(
        participantUUID: UUID,
        apiConfiguration: APIConfiguration,
        httpSession: HTTPSession,
        authTokenProvider: AuthTokenProvider
    ) {
        self.httpSession = httpSession
        self.requestFactory = HTTPRequestFactory(
            baseURL: apiConfiguration.participantBaseURL(withUUID: participantUUID),
            authTokenProvider: authTokenProvider
        )
    }

    // MARK: - API

    func makeCall(sdp: String, present: String?) async throws -> Call {
        var request = try await requestFactory.request(withName: "calls", method: .POST)
        try request.setJSONBody([
            "call_type": "WEBRTC",
            "sdp": sdp,
            "present": present
        ])
        return try await httpSession.json(for: request, decoder: decoder)
    }
}
