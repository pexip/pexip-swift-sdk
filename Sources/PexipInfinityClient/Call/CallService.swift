import Foundation
import PexipCore

// MARK: - Protocol

public typealias DTMFSignals = PexipCore.DTMFSignals

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
        - sdp: The new local SDP (optional)
        - token: Current valid API token
     - Returns: The result is true if successful, false otherwise.
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func ack(sdp: String?, token: ConferenceToken) async throws -> Bool

    /**
     Sends a new local SDP.
     - Parameters:
        - sdp: The new local SDP
        - token: Current valid API token
     - Returns: A new remote SDP
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func update(sdp: String, token: ConferenceToken) async throws -> String?

    /**
     Sends DTMF digits to the participant (gateway call only).
     See [documentation](https://docs.pexip.com/api_client/api_rest.htm?Highlight=api#call_dtmf)

     - Parameters:
        - signals: The DTMF signals to send
        - token: Current valid API token

     - Returns: The result is true if successful, false otherwise.
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    @discardableResult
    func dtmf(signals: DTMFSignals, token: ConferenceToken) async throws -> Bool

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
    var decoder = JSONDecoder()

    func newCandidate(iceCandidate: IceCandidate, token: ConferenceToken) async throws {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("new_candidate"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        try request.setJSONBody(iceCandidate)
        _ = try await client.data(for: request)
    }

    func ack(sdp: String?, token: ConferenceToken) async throws -> Bool {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("ack"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))

        if let sdp = sdp {
            try request.setJSONBody([
                "sdp": sdp
            ])
        }

        return try await client.json(for: request)
    }

    func update(sdp: String, token: ConferenceToken) async throws -> String? {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("update"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        try request.setJSONBody([
            "sdp": sdp
        ])

        let (data, _) = try await client.data(for: request)

        do {
            return try decoder.decode(
                ResponseContainer<String>.self,
                from: data
            ).result
        } catch {
            return try decoder.decode(
                ResponseContainer<CallDetails>.self,
                from: data
            ).result.sdp
        }
    }

    @discardableResult
    func dtmf(signals: DTMFSignals, token: ConferenceToken) async throws -> Bool {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("dtmf"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        try request.setJSONBody([
            "digits": signals.rawValue
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
