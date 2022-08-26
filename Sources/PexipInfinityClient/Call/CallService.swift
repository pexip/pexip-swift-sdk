import Foundation

// MARK: - Protocol

public protocol CallService {
    /**
     Sends a new ICE candidate if doing trickle ICE.
     - Parameters:
        - iceCandidate: The ICE candidate to send
        - token: Current valid API token
     - Returns: The result is true if successful, false otherwise.
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func newCandidate(iceCandidate: IceCandidate, token: ConferenceToken) async throws

    /**
     Starts media for the specified call (WebRTC calls only).
     - Parameters:
        - token: Current valid API token
     - Returns: The result is true if successful, false otherwise.
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func ack(token: ConferenceToken) async throws -> Bool

    /**
     Sends a new local SDP.
     - Parameters:
        - sdp: The new local SDP
        - token: Current valid API token
     - Returns: A new remote SDP
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func update(sdp: String, token: ConferenceToken) async throws -> String

    /**
     Disconnects the specified call.
     - Parameters:
        - token: Current valid API token
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func disconnect(token: ConferenceToken) async throws
}

// MARK: - Implementation

struct DefaultCallService: CallService {
    let baseURL: URL
    let client: HTTPClient

    func newCandidate(iceCandidate: IceCandidate, token: ConferenceToken) async throws {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("new_candidate"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        try request.setJSONBody(iceCandidate)
        _ = try await client.data(for: request)
    }

    func ack(token: ConferenceToken) async throws -> Bool {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("ack"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        return try await client.json(for: request)
    }

    func update(sdp: String, token: ConferenceToken) async throws -> String {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("update"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        try request.setJSONBody([
            "sdp": sdp
        ])
        return try await client.json(for: request)
    }

    func disconnect(token: ConferenceToken) async throws {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("disconnect"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        _ = try await client.data(for: request)
    }
}
