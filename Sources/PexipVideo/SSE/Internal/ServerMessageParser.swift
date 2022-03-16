import Foundation

struct ServerMessageParser {
    let logger: CategoryLogger
    let decoder: JSONDecoder

    func message(from event: EventStreamEvent) -> ServerEvent.Message? {
        guard let nameString = event.name else {
            logger.debug("Received event without a name")
            return nil
        }

        guard let name = ServerEvent.Name(rawValue: nameString) else {
            logger.debug("SSE event: '\(nameString)' was not handled")
            return nil
        }

        let data = event.data?.data(using: .utf8)

        do {
            return try message(withName: name, data: data)
        } catch {
            logger.error("Failed to decode SSE event: '\(name)', error: \(error)")
            return nil
        }
    }

    private func message(
        withName name: ServerEvent.Name,
        data: Data?
    ) throws -> ServerEvent.Message {
        switch name {
        case .chat:
            return .chat(try decoder.decode(ChatMessage.self, from: data))
        case .presentationStarted:
            let message = try decoder.decode(PresentationDetails.self, from: data)
            return .presentationStarted(message)
        case .presentationStopped:
            return .presentationStopped
        case .participantSyncBegan:
            return .participantSyncBegan
        case .participantSyncEnded:
            return .participantSyncEnded
        case .participantCreated:
            return .participantCreated(try decoder.decode(Participant.self, from: data))
        case .participantUpdated:
            return .participantUpdated(try decoder.decode(Participant.self, from: data))
        case .participantDeleted:
            let details = try decoder.decode(ParticipantDeleteDetails.self, from: data)
            return .participantDeleted(details)
        case .callDisconnected:
            let message = try decoder.decode(CallDisconnectDetails.self, from: data)
            return .callDisconnected(message)
        case .clientDisconnected:
            let message = try decoder.decode(ClientDisconnectDetails.self, from: data)
            return .clientDisconnected(message)
        }
    }
}

// MARK: - Private extensions

private extension JSONDecoder {
    func decode<T>(_ type: T.Type, from data: Data?) throws -> T where T: Decodable {
        try decode(type, from: data.orThrow(HTTPError.noDataInResponse))
    }
}
