import Foundation
import PexipUtils

struct ServerMessageParser {
    var decoder = JSONDecoder()
    var logger: Logger?

    func message(from event: EventSourceEvent) -> ServerEvent.Message? {
        guard let nameString = event.name else {
            logger?.debug("Received event without a name")
            return nil
        }

        guard let name = ServerEvent.Name(rawValue: nameString) else {
            logger?.debug("SSE event: '\(nameString)' was not handled")
            return nil
        }

        let data = event.data?.data(using: .utf8)

        do {
            return try message(withName: name, data: data)
        } catch {
            logger?.error("Failed to decode SSE event: '\(name)', error: \(error)")
            return nil
        }
    }

    private func message(
        withName name: ServerEvent.Name,
        data: Data?
    ) throws -> ServerEvent.Message {
        switch name {
        case .conferenceUpdate:
            let message = try decoder.decode(ConferenceStatus.self, from: data)
            return .conferenceUpdate(message)
        case .messageReceived:
            return .messageReceived(try decoder.decode(ChatMessage.self, from: data))
        case .presentationStart:
            let message = try decoder.decode(PresentationStartMessage.self, from: data)
            return .presentationStart(message)
        case .presentationStop:
            return .presentationStop
        case .participantSyncBegin:
            return .participantSyncBegin
        case .participantSyncEnd:
            return .participantSyncEnd
        case .participantCreate:
            return .participantCreate(try decoder.decode(Participant.self, from: data))
        case .participantUpdate:
            return .participantUpdate(try decoder.decode(Participant.self, from: data))
        case .participantDelete:
            let details = try decoder.decode(ParticipantDeleteMessage.self, from: data)
            return .participantDelete(details)
        case .callDisconnected:
            let message = try decoder.decode(CallDisconnectMessage.self, from: data)
            return .callDisconnected(message)
        case .clientDisconnected:
            let message = try decoder.decode(ClientDisconnectMessage.self, from: data)
            return .clientDisconnected(message)
        case .liveCaptions:
            let message = try decoder.decode(LiveCaptions.self, from: data)
            return .liveCaptions(message)
        }
    }
}

// MARK: - Private extensions

private extension JSONDecoder {
    func decode<T>(_ type: T.Type, from data: Data?) throws -> T where T: Decodable {
        guard let data = data else {
            throw HTTPError.noDataInResponse
        }
        return try decode(type, from: data)
    }
}
