import Combine
import Foundation

// MARK: - Delegate

public enum ParticipantEvent: Hashable {
    case added(Participant)
    case updated(Participant)
    case deleted(Participant)
    case reloaded([Participant])
}

public protocol RosterDelegate: AnyObject {
    func roster(_ roster: Roster, didReceiveParticipantEvent event: ParticipantEvent)
}

// MARK: - Roster list

public final class Roster: ObservableObject {
    public typealias ReloadParticipants = () async throws -> [Participant]

    /// The display name of the current participant.
    @Published public private(set) var currentParticipantName: String
    /// The full participant list of the conference.
    @Published public private(set) var participants = [Participant]()
    /// Roster event publisher (participant added, updated, deleted, etc).
    public var eventPublisher: AnyPublisher<ParticipantEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    /// The UUID of the current participant.
    public let currentParticipantId: UUID
    /// The object that acts as the delegate of the roster list.
    public weak var delegate: RosterDelegate?
    private let eventSubject = PassthroughSubject<ParticipantEvent, Never>()
    private let storage: Storage
    private let _avatarURL: (UUID) -> URL?

    // MARK: - Init

    public init(
        currentParticipantId: UUID,
        currentParticipantName: String,
        participants: [Participant] = [],
        avatarURL: @escaping (UUID) -> URL?
    ) {
        self.currentParticipantId = currentParticipantId
        self.currentParticipantName = currentParticipantName
        self.storage = Storage(participants: participants)
        self.participants = participants
        self._avatarURL = avatarURL
    }

    // MARK: - Public

    /**
     Checks if the given participant is the current user
     - Parameters:
        - participant: A participant from the participant list
     - Returns: true if the given participant is the current user
     */
    public func isCurrentParticipant(_ participant: Participant) -> Bool {
        participant.id == currentParticipantId
    }

    /**
     Returns the image representing the current participant.
     */
    public var currentParticipantavatarURL: URL? {
        _avatarURL(currentParticipantId)
    }

    /**
     Returns the image url of a conference participant or directory contact.
     - Parameters:
        - participant: A participant from the participant list
     - Returns: The image url of a conference participant or directory contact.
     */
    public func avatarURL(for participant: Participant) -> URL? {
        _avatarURL(participant.id)
    }

    // MARK: - Internal

    func setSyncing(_ value: Bool) async {
        await storage.setSyncing(value)
        if !value {
            await onReload()
        }
    }

    func addParticipant(_ participant: Participant) async {
        await storage.addParticipant(participant)

        if isCurrentParticipant(participant) {
            currentParticipantName = participant.displayName
        }

        if await !storage.isSyncing {
            let participants = await storage.participants
            await publishParticipants(participants, event: .added(participant))
        }
    }

    func updateParticipant(_ participant: Participant) async {
        guard await storage.updateParticipant(participant) else {
            return
        }

        if isCurrentParticipant(participant) {
            currentParticipantName = participant.displayName
        }

        if await !storage.isSyncing {
            let participants = await storage.participants
            await publishParticipants(participants, event: .updated(participant))
        }
    }

    func removeParticipant(withId id: UUID) async {
        guard let participant = await storage.removeParticipant(withId: id) else {
            return
        }

        if await !storage.isSyncing {
            let participants = await storage.participants
            await publishParticipants(participants, event: .deleted(participant))
        }
    }

    func clear() async {
        await storage.clear()
        await onReload()
    }

    // MARK: - Private

    private func onReload() async {
        let participants = await storage.participants
        await publishParticipants(participants, event: .reloaded(participants))
    }

    private func publishParticipants(
        _ participants: [Participant],
        event: ParticipantEvent
    ) async {
        await MainActor.run {
            self.participants = participants
            eventSubject.send(event)
            delegate?.roster(self, didReceiveParticipantEvent: event)
        }
    }
}

// MARK: - Private types

private extension Roster {
    actor Storage {
        private(set) var participants = [Participant]()
        private(set) var isSyncing = false

        init(participants: [Participant]) {
            self.participants = participants
        }

        func setSyncing(_ value: Bool) {
            isSyncing = value
            if isSyncing {
                participants.removeAll()
            }
        }

        func addParticipant(_ participant: Participant) {
            participants.append(participant)
        }

        func updateParticipant(_ participant: Participant) async -> Bool {
            guard let index = indexOfParticipant(withId: participant.id) else {
                return false
            }
            participants[index] = participant
            return true
        }

        func removeParticipant(withId id: UUID) async -> Participant? {
            guard let index = indexOfParticipant(withId: id) else {
                return nil
            }
            return participants.remove(at: index)
        }

        func clear() async {
            isSyncing = false
            participants.removeAll()
        }

        private func indexOfParticipant(withId id: UUID) -> Int? {
            participants.firstIndex(where: { $0.id == id })
        }
    }
}
