import Combine

// MARK: - Delegate

public protocol RosterListDelegate: AnyObject {
    func rosterList(
        _ rosterList: RosterList,
        didAddParticipant participant: Participant
    )

    func rosterList(
        _ rosterList: RosterList,
        didUpdateParticipant participant: Participant
    )

    func rosterList(
        _ rosterList: RosterList,
        didRemoveParticipant participant: Participant
    )

    func rosterList(
        _ rosterList: RosterList,
        didReloadParticipants participants: [Participant]
    )
}

// MARK: - Roster list

public final class RosterList: ObservableObject {
    /// The full participant list of the conference.
    @Published public private(set) var participants = [Participant]()
    /// The object that acts as the delegate of the roster list.
    public weak var delegate: RosterListDelegate?
    private let storage: Storage
    private let avatarURL: (UUID) -> URL?

    // MARK: - Init

    public init(
        participants: [Participant] = [],
        avatarURL: @escaping (UUID) -> URL?
    ) {
        self.storage = Storage(participants: participants)
        self.participants = participants
        self.avatarURL = avatarURL
    }

    // MARK: - Internal

    func setSyncing(_ value: Bool) async {
        await storage.setSyncing(value)
        if !value {
            await onReload()
        }
    }

    func addParticipant(_ participant: Participant) async {
        let participant = participantWithAvatar(from: participant)
        await storage.addParticipant(participant)

        if await !storage.isSyncing {
            let participants = await storage.participants
            await MainActor.run {
                self.participants = participants
                delegate?.rosterList(self, didAddParticipant: participant)
            }
        }
    }

    func updateParticipant(_ participant: Participant) async {
        let participant = participantWithAvatar(from: participant)

        guard await storage.updateParticipant(participant) else {
            return
        }

        if await !storage.isSyncing {
            let participants = await storage.participants
            await MainActor.run {
                self.participants = participants
                delegate?.rosterList(self, didUpdateParticipant: participant)
            }
        }
    }

    func removeParticipant(withId id: UUID) async {
        guard let participant = await storage.removeParticipant(withId: id) else {
            return
        }

        if await !storage.isSyncing {
            let participants = await storage.participants
            await MainActor.run {
                self.participants = participants
                delegate?.rosterList(self, didRemoveParticipant: participant)
            }
        }
    }

    func clear() async {
        await storage.clear()
        await onReload()
    }

    // MARK: - Private

    private func onReload() async {
        let participants = await storage.participants
        await MainActor.run {
            self.participants = participants
            delegate?.rosterList(self, didReloadParticipants: participants)
        }
    }

    private func participantWithAvatar(from participant: Participant) -> Participant {
        var participant = participant
        participant.avatarURL = avatarURL(participant.id)
        return participant
    }
}

// MARK: - Private types

private extension RosterList {
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
