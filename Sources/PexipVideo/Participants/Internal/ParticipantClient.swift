import Foundation

// MARK: - Protocol

/// Pexip client REST API v2.
protocol ParticipantClientProtocol {
    /**
     Returns the image url of a conference participant or directory contact.
     - Parameters:
        - participantId: The ID of the participant
     - Returns: The image url of a conference participant or directory contact.
     */
    func avatarURL(participantId: UUID) -> URL

    /**
     Mutes a participant's video.
     - Parameters:
        - participantId: The ID of the participant
     - Returns: The result is true if successful, false otherwise.
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    @discardableResult
    func muteVideo(participantId: UUID) async throws -> Bool

    /**
     Unmutes a participant's video.
     - Parameters:
        - participantId: The ID of the participant
     - Returns: The result is true if successful, false otherwise.
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    @discardableResult
    func unmuteVideo(participantId: UUID) async throws -> Bool
}

// MARK: - Implementation

extension InfinityClient: ParticipantClientProtocol {
    func avatarURL(participantId: UUID) -> URL {
        url(for: .participant(id: participantId))
            .appendingPathComponent("avatar.jpg")
    }

    @discardableResult
    func muteVideo(participantId: UUID) async throws -> Bool {
        let request = try await request(
            withMethod: .POST,
            path: .participant(id: participantId),
            name: "video_muted"
        )
        return try await json(for: request)
    }

    @discardableResult
    func unmuteVideo(participantId: UUID) async throws -> Bool {
        let request = try await request(
            withMethod: .POST,
            path: .participant(id: participantId),
            name: "video_unmuted"
        )
        return try await json(for: request)
    }
}
