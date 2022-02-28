import Foundation

struct ServerMessageParser {
    let logger: CategoryLogger
    let decoder: JSONDecoder

    func message(from event: EventStreamEvent) -> ServerEvent.Message? {
        guard let name = event.name else {
            logger.debug("Received event without a name")
            return nil
        }

        let data = event.data?.data(using: .utf8)

        do {
            switch name {
            case "message_received":
                return .chat(try decoder.decode(ChatMessage.self, from: data))
            case "call_disconnected":
                let message = try decoder.decode(ServerEvent.CallDisconnected.self, from: data)
                return .callDisconnected(message)
            case "disconnect":
                let message = try decoder.decode(ServerEvent.Disconnect.self, from: data)
                return .disconnect(message)
            default:
                logger.debug("SSE event: '\(name)' was not handled")
                return nil
            }
        } catch {
            logger.error("Failed to decode SSE event: '\(name)', error: \(error)")
            return nil
        }
    }
}

// MARK: - Private extensions

private extension JSONDecoder {
    func decode<T>(_ type: T.Type, from data: Data?) throws -> T where T: Decodable {
        try decode(type, from: data.orThrow(HTTPError.noDataInResponse))
    }
}
