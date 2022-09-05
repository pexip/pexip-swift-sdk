import Foundation
import PexipCore

struct ConferenceEventParser: InfinityEventParser {
    var decoder = JSONDecoder()
    var logger: Logger?

    func parseEventData(from event: HTTPEvent) -> ConferenceEvent? {
        logger?.debug(
            "Got conference event with ID: \(event.id.debug), name: \(event.name.debug)"
        )

        guard let nameString = event.name else {
            logger?.debug("Received conference event without a name")
            return nil
        }

        guard let name = ConferenceEvent.Name(rawValue: nameString) else {
            logger?.debug("Conference event '\(nameString)' was not handled")
            return nil
        }

        let data = event.data?.data(using: .utf8)

        do {
            return try conferenceEvent(withName: name, data: data)
        } catch {
            logger?.error("Failed to decode conference event: '\(name)', error: \(error)")
            return nil
        }
    }

    // swiftlint:disable cyclomatic_complexity
    private func conferenceEvent(
        withName name: ConferenceEvent.Name,
        data: Data?
    ) throws -> ConferenceEvent {
        switch name {
        case .conferenceUpdate:
            let status = try decoder.decode(ConferenceStatus.self, from: data)
            return .conferenceUpdate(status)
        case .messageReceived:
            return .messageReceived(try decoder.decode(ChatMessage.self, from: data))
        case .presentationStart:
            let event = try decoder.decode(PresentationStartEvent.self, from: data)
            return .presentationStart(event)
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
            let event = try decoder.decode(ParticipantDeleteEvent.self, from: data)
            return .participantDelete(event)
        case .callDisconnected:
            let event = try decoder.decode(CallDisconnectEvent.self, from: data)
            return .callDisconnected(event)
        case .clientDisconnected:
            let event = try decoder.decode(ClientDisconnectEvent.self, from: data)
            return .clientDisconnected(event)
        case .liveCaptions:
            let details = try decoder.decode(LiveCaptions.self, from: data)
            return .liveCaptions(details)
        }
    }
}
