import Foundation

// MARK: - Protocol

/// Pexip client REST API v2.
protocol ServerSentEventClientProtocol {
    func eventStream(
        lastEventId: String?
    ) async throws -> AsyncThrowingStream<MessageEvent, Error>
}

// MARK: - Implementation

extension InfinityClient: ServerSentEventClientProtocol {
    func eventStream(
        lastEventId: String?
    ) async throws -> AsyncThrowingStream<MessageEvent, Error> {
        eventStream(
            withRequest: try await request(
                withMethod: .GET,
                path: .conference,
                name: "events"
            ),
            lastEventId: lastEventId
        )
    }
}
