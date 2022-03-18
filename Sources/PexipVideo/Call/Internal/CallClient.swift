import Foundation

// MARK: - Protocol

/// Pexip client REST API v2.
protocol CallClientProtocol {
    /**
     Upgrades this connection to have an audio/video call element.

     - Parameters:
        - kind: The type of the call
        - participantId: The ID of the participant
        - sdp: Contains the SDP of the sender
     - Returns: Information about the service you are connecting to
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func makeCall(
        kind: CallKind,
        participantId: UUID,
        sdp: String
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
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func disconnect(participantId: UUID, callId: UUID) async throws

    /**
     Sends a new ICE candidate if doing trickle ICE.
     - Parameters:
        - participantId: The ID of the participant
        - callId: The ID of the call
        - iceCandidate: The ICE candidate to send
     - Returns: The result is true if successful, false otherwise.
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func newCandidate(
        participantId: UUID,
        callId: UUID,
        iceCandidate: IceCandidate
    ) async throws
}

// MARK: - Implementation

extension InfinityClient: CallClientProtocol {
    func makeCall(
        kind: CallKind,
        participantId: UUID,
        sdp: String
    ) async throws -> CallDetails {
        var request = try await request(
            withMethod: .POST,
            path: .participant(id: participantId),
            name: "calls"
        )
        request.timeoutInterval = 62

        var parameters = [
            "call_type": "WEBRTC",
            "sdp": sdp
        ]
        var present: String?

        switch kind {
        case .call(let presentationInMix):
            present = presentationInMix ? "main" : nil
        case .presentationReceiver:
            present = "receive"
        case .presentationSender:
            present = "send"
        }

        if let present = present {
            parameters["present"] = present
        }

        try request.setJSONBody(parameters)
        return try await json(for: request)
    }

    func ack(participantId: UUID, callId: UUID) async throws -> Bool {
        try await json(for: try await request(
            withMethod: .POST,
            path: .call(participantId: participantId, callId: callId),
            name: "ack"
        ))
    }

    func disconnect(participantId: UUID, callId: UUID) async throws {
        let request = try await request(
            withMethod: .POST,
            path: .call(participantId: participantId, callId: callId),
            name: "disconnect"
        )
        _ = try await data(for: request)
    }

    func newCandidate(
        participantId: UUID,
        callId: UUID,
        iceCandidate: IceCandidate
    ) async throws {
        var request = try await request(
            withMethod: .POST,
            path: .call(participantId: participantId, callId: callId),
            name: "new_candidate"
        )
        try request.setJSONBody(iceCandidate)
        _ = try await data(for: request)
    }
}
