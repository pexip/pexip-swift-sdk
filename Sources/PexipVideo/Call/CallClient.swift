import Foundation

// MARK: - Protocol

/// Pexip client REST API v2.
protocol CallClientProtocol {
    /**
     Upgrades this connection to have an audio/video call element.

     - Parameters:
        - participantId: The ID of the participant
        - sdp: Contains the SDP of the sender
        - present: Optional field. Contains "send" or "receive"
                   to act as a presentation stream rather than a main audio/video stream.
     - Returns: Information about the service you are connecting to
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func makeCall(
        participantId: UUID,
        sdp: String,
        present: String?
    ) async throws -> CallDetails

    /**
     Starts media for the specified call (WebRTC calls only).
     - Parameters:
        - participantId: The ID of the participant
        - callId: The ID of the call
     - Returns: The result is true if successful, false otherwise.
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func ack(participantId: UUID, callId: UUID) async throws -> Bool

    /**
     Disconnects the specified call.
     - Parameters:
        - participantId: The ID of the participant
        - callId: The ID of the call
     - Returns: The result is true if successful, false otherwise.
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func disconnect(participantId: UUID, callId: UUID) async throws -> Bool
}

// MARK: - Implementation

extension InfinityClient: CallClientProtocol {
    func makeCall(
        participantId: UUID,
        sdp: String,
        present: String?
    ) async throws -> CallDetails {
        var request = try await request(
            withMethod: .POST,
            path: .participant(id: participantId),
            name: "calls"
        )
        try request.setJSONBody([
            "call_type": "WEBRTC",
            "sdp": sdp,
            "present": present
        ])
        return try await json(for: request)
    }

    func ack(participantId: UUID, callId: UUID) async throws -> Bool {
        try await json(for: try await request(
            withMethod: .POST,
            path: .call(participantId: participantId, callId: callId),
            name: "ack"
        ))
    }

    func disconnect(participantId: UUID, callId: UUID) async throws -> Bool {
        try await json(for: try await request(
            withMethod: .POST,
            path: .call(participantId: participantId, callId: callId),
            name: "disconnect"
        ))
    }
}
