import Foundation

// MARK: - Protocol

public protocol ParticipantService {
    /**
     Upgrades this connection to have an audio/video call element.
     See [documentation](https://docs.pexip.com/api_client/api_rest.htm?Highlight=api#calls)

     - Parameters:
        - fields: Request fields
        - token: Current valid API token
     - Returns: The SDP of the Pexip node, and a call UUID
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func calls(
        fields: CallsFields,
        token: Token
    ) async throws -> CallDetails

    /**
     - Returns: The image url of a conference participant or directory contact.
     */
    func avatarURL() -> URL

    /**
     Mutes a participant's audio.
     See [documentation](https://docs.pexip.com/api_client/api_rest.htm#mute)

     - Parameters:
        - token: Current valid API token
     - Returns: The result is true if successful, false otherwise.
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    @discardableResult
    func mute(token: Token) async throws -> Bool

    /**
     Unmutes a participant's audio.
     See [documentation](https://docs.pexip.com/api_client/api_rest.htm#mute)

     - Parameters:
        - token: Current valid API token
     - Returns: The result is true if successful, false otherwise.
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    @discardableResult
    func unmute(token: Token) async throws -> Bool

    /**
     Mutes a participant's video.
     See [documentation](https://docs.pexip.com/api_client/api_rest.htm#videomute)

     - Parameters:
        - token: Current valid API token
     - Returns: The result is true if successful, false otherwise.
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    @discardableResult
    func videoMuted(token: Token) async throws -> Bool

    /**
     Unmutes a participant's video.
     See [documentation](https://docs.pexip.com/api_client/api_rest.htm#videomute)

     - Parameters:
        - token: Current valid API token
     - Returns: The result is true if successful, false otherwise.
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    @discardableResult
    func videoUnmuted(token: Token) async throws -> Bool

    /**
     Starts sending local presentation.

     - Parameters:
        - token: Current valid API token
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func takeFloor(token: Token) async throws

    /**
     Stops sending local presentation.

     - Parameters:
        - token: Current valid API token
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func releaseFloor(token: Token) async throws

    /**
     Starts receiving live caption events.

     - Parameters:
        - token: Current valid API token
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func showLiveCaptions(token: Token) async throws

    /**
     Stop receiving live caption events.

     - Parameters:
        - token: Current valid API token
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func hideLiveCaptions(token: Token) async throws

    /**
     Sets the call ID.
     - Parameters:
        - id: The ID of the call
     - Returns: A new instance of ``CallService``
     */
    func call(id: UUID) -> CallService
}

// MARK: - Implementation

struct DefaultParticipantService: ParticipantService {
    let baseURL: URL
    let client: HTTPClient

    func calls(
        fields: CallsFields,
        token: Token
    ) async throws -> CallDetails {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("calls"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        request.timeoutInterval = 62
        try request.setJSONBody(fields)
        return try await client.json(for: request)
    }

    func avatarURL() -> URL {
        baseURL.appendingPathComponent("avatar.jpg")
    }

    @discardableResult
    func mute(token: Token) async throws -> Bool {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("mute"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        return try await client.json(for: request)
    }

    @discardableResult
    func unmute(token: Token) async throws -> Bool {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("unmute"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        return try await client.json(for: request)
    }

    @discardableResult
    func videoMuted(token: Token) async throws -> Bool {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("video_muted"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        return try await client.json(for: request)
    }

    @discardableResult
    func videoUnmuted(token: Token) async throws -> Bool {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("video_unmuted"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        return try await client.json(for: request)
    }

    func takeFloor(token: Token) async throws {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("take_floor"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        _ = try await client.data(for: request)
    }

    func releaseFloor(token: Token) async throws {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("release_floor"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        _ = try await client.data(for: request)
    }

    func showLiveCaptions(token: Token) async throws {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("show_live_captions"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        _ = try await client.data(for: request)
    }

    func hideLiveCaptions(token: Token) async throws {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("hide_live_captions"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        _ = try await client.data(for: request)
    }

    func call(id: UUID) -> CallService {
        let url = baseURL
            .appendingPathComponent("calls")
            .appendingPathComponent(id.uuidString.lowercased())
        return DefaultCallService(baseURL: url, client: client)
    }
}
