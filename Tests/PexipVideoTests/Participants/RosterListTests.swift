import XCTest
import Combine
@testable import PexipVideo

final class RosterListTests: XCTestCase {
    private var rosterList: RosterList!
    private var delegate: RosterListDelegateMock!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        delegate = RosterListDelegateMock()
        rosterList = RosterList(participants: [], avatarURL: { id in
            Participant.avatarURL(id: id)
        })
        rosterList.delegate = delegate
    }

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - Tests

    func testInit() {
        let participants = [
            Participant.stub(withId: UUID(), displayName: "GuestA"),
            Participant.stub(withId: UUID(), displayName: "GuestB")
        ]
        rosterList = RosterList(participants: participants, avatarURL: { _ in nil })
        XCTAssertEqual(rosterList.participants, participants)
    }

    func testSetSyncing() async {
        // 1. Prepare test data
        let participantsToAdd = [
            Participant.stub(withId: UUID(), displayName: "Guest1"),
            Participant.stub(withId: UUID(), displayName: "Guest2"),
            Participant.stub(withId: UUID(), displayName: "Guest3")
        ]
        let participantsToUpdate = [
            Participant.stub(
                withId: participantsToAdd[1].id,
                displayName: "Updated Guest2"
            )
        ]
        let participantsToRemove = [participantsToAdd[0]]
        let expectedParticipants = [
            participantsToUpdate[0].withAvatarURL(),
            participantsToAdd[2].withAvatarURL()
        ]
        var publishCount = 0
        var publishedParticipants = [[Participant]]()

        // 2. Subscibe to updates
        rosterList.$participants.sink { participants in
            publishedParticipants.append(participants)
            publishCount += 1
        }.store(in: &cancellables)

        // 3. Start syncing
        await rosterList.setSyncing(true)

        for participant in participantsToAdd {
            await rosterList.addParticipant(participant)
        }

        for participant in participantsToUpdate {
            await rosterList.updateParticipant(participant)
        }

        for participant in participantsToRemove {
            await rosterList.removeParticipant(withId: participant.id)
        }

        await rosterList.setSyncing(false)

        // 4. Assert

        XCTAssertEqual(rosterList.participants, expectedParticipants)
        XCTAssertEqual(delegate.actions, [.reload(expectedParticipants)])
        XCTAssertEqual(publishedParticipants, [[], expectedParticipants])
        XCTAssertEqual(publishCount, 2)
    }

    func testAddParticipant() async {
        // 1. Prepare test data
        let participantA = Participant.stub(withId: UUID(), displayName: "GuestA")
        let participantB = Participant.stub(withId: UUID(), displayName: "GuestB")
        var publishCount = 0
        var publishedParticipants = [[Participant]]()
        let expectedParticipants = [
            participantA.withAvatarURL(),
            participantB.withAvatarURL()
        ]

        // 2. Subscibe to updates
        rosterList.$participants.sink { participants in
            publishedParticipants.append(participants)
            publishCount += 1
        }.store(in: &cancellables)

        // 3. Add participant
        await rosterList.addParticipant(participantA)
        await rosterList.addParticipant(participantB)

        // 4. Assert
        XCTAssertEqual(rosterList.participants, expectedParticipants)
        XCTAssertEqual(
            delegate.actions,
            [
                .add(participantA.withAvatarURL()),
                .add(participantB.withAvatarURL())
            ]
        )
        XCTAssertEqual(
            publishedParticipants,
            [
                [],
                [participantA.withAvatarURL()],
                [participantA.withAvatarURL(), participantB.withAvatarURL()]
            ]
        )
        XCTAssertEqual(publishCount, 3)
    }

    func testUpdateParticipant() async {
        // 1. Prepare test data
        let participantA = Participant.stub(withId: UUID(), displayName: "GuestA")
        let participantB = Participant.stub(withId: participantA.id, displayName: "GuestB")
        var publishCount = 0
        var publishedParticipants = [[Participant]]()
        let expectedParticipants = [participantB.withAvatarURL()]

        // 2. Subscibe to updates
        rosterList.$participants.sink { participants in
            publishedParticipants.append(participants)
            publishCount += 1
        }.store(in: &cancellables)

        // 3. Add and update participant
        await rosterList.addParticipant(participantA)
        await rosterList.updateParticipant(participantB)

        // 4. Assert
        XCTAssertEqual(rosterList.participants, expectedParticipants)
        XCTAssertEqual(
            delegate.actions,
            [.add(participantA.withAvatarURL()), .update(participantB.withAvatarURL())]
        )
        XCTAssertEqual(
            publishedParticipants,
            [[], [participantA.withAvatarURL()], [participantB.withAvatarURL()]]
        )
        XCTAssertEqual(publishCount, 3)
    }

    func testUpdateParticipantWithNotExisingId() async {
        // 1. Prepare test data
        let participantA = Participant.stub(withId: UUID(), displayName: "GuestA")
        let participantB = Participant.stub(withId: UUID(), displayName: "GuestB")
        var publishCount = 0
        var publishedParticipants = [[Participant]]()
        let expectedParticipants = [participantA.withAvatarURL()]

        // 2. Subscibe to updates
        rosterList.$participants.sink { participants in
            publishedParticipants.append(participants)
            publishCount += 1
        }.store(in: &cancellables)

        // 3. Add and update participant
        await rosterList.addParticipant(participantA)
        await rosterList.updateParticipant(participantB)

        // 4. Assert
        XCTAssertEqual(rosterList.participants, expectedParticipants)
        XCTAssertEqual(delegate.actions, [.add(participantA.withAvatarURL())])
        XCTAssertEqual(publishedParticipants, [[], [participantA.withAvatarURL()]])
        XCTAssertEqual(publishCount, 2)
    }

    func testRemoveParticipant() async {
        // 1. Prepare test data
        let participantA = Participant.stub(withId: UUID(), displayName: "GuestA")
        let participantB = Participant.stub(withId: UUID(), displayName: "GuestB")
        var publishCount = 0
        var publishedParticipants = [[Participant]]()
        let expectedParticipants = [participantB.withAvatarURL()]

        // 2. Subscibe to updates
        rosterList.$participants.sink { participants in
            publishedParticipants.append(participants)
            publishCount += 1
        }.store(in: &cancellables)

        // 3. Add and remove participants
        await rosterList.addParticipant(participantA)
        await rosterList.addParticipant(participantB)
        await rosterList.removeParticipant(withId: participantA.id)

        // 4. Assert
        XCTAssertEqual(rosterList.participants, expectedParticipants)
        XCTAssertEqual(
            delegate.actions,
            [
                .add(participantA.withAvatarURL()),
                .add(participantB.withAvatarURL()),
                .remove(participantA.withAvatarURL())
            ]
        )
        XCTAssertEqual(
            publishedParticipants,
            [
                [],
                [participantA.withAvatarURL()],
                [participantA.withAvatarURL(), participantB.withAvatarURL()],
                [participantB.withAvatarURL()]
            ]
        )
        XCTAssertEqual(publishCount, 4)
    }

    func testRemoveParticipantWithNotExistingId() async {
        // 1. Prepare test data
        let participant = Participant.stub(withId: UUID(), displayName: "GuestA")
        var publishCount = 0
        var publishedParticipants = [[Participant]]()
        let expectedParticipants = [participant.withAvatarURL()]

        // 2. Subscibe to updates
        rosterList.$participants.sink { participants in
            publishedParticipants.append(participants)
            publishCount += 1
        }.store(in: &cancellables)

        // 3. Add and remove participants
        await rosterList.addParticipant(participant)
        await rosterList.removeParticipant(withId: UUID())

        // 4. Assert
        XCTAssertEqual(rosterList.participants, expectedParticipants)
        XCTAssertEqual(delegate.actions, [.add(participant.withAvatarURL())])
        XCTAssertEqual(publishedParticipants, [[], [participant.withAvatarURL()]])
        XCTAssertEqual(publishCount, 2)
    }

    func testClear() async {
        // 1. Prepare test data
        let participant = Participant.stub(withId: UUID(), displayName: "GuestA")
        var publishCount = 0
        var publishedParticipants = [[Participant]]()

        // 2. Subscibe to updates
        rosterList.$participants.sink { participants in
            publishedParticipants.append(participants)
            publishCount += 1
        }.store(in: &cancellables)

        // 3. Add and clear participants
        await rosterList.addParticipant(participant)
        await rosterList.clear()

        // 4. Assert
        XCTAssertTrue(rosterList.participants.isEmpty)
        XCTAssertEqual(
            delegate.actions,
            [
                .add(participant.withAvatarURL()),
                .reload([])
            ]
        )
        XCTAssertEqual(
            publishedParticipants,
            [[], [participant.withAvatarURL()], []]
        )
        XCTAssertEqual(publishCount, 3)
    }
}

// MARK: - Stubs

extension Participant {
    static func avatarURL(id: UUID) -> URL? {
        URL(string: "https://vc.example.com/api/participant/\(id)/avatar.jpg")
    }

    static func stub(withId id: UUID, displayName: String) -> Participant {
        Participant(
            id: id,
            displayName: displayName,
            role: .guest,
            serviceType: .conference,
            callDirection: .inbound,
            hasMedia: true,
            isExternal: false,
            isStreamingConference: false,
            isVideoMuted: false,
            canReceivePresentation: true,
            isConnectionEncrypted: true,
            isDisconnectSupported: true,
            isFeccSupported: false,
            isAudioOnlyCall: false,
            isMuted: false,
            isPresenting: false,
            isVideoCall: true,
            isMuteSupported: true,
            isTransferSupported: true
        )
    }

    func withAvatarURL() -> Participant {
        var participant = self
        participant.avatarURL = Participant.avatarURL(id: id)
        return participant
    }
}

// MARK: - Mocks

private final class RosterListDelegateMock: RosterListDelegate {
    enum Action: Equatable {
        case add(Participant)
        case update(Participant)
        case remove(Participant)
        case reload([Participant])
    }

    private(set) var actions = [Action]()

    func rosterList(
        _ rosterList: RosterList,
        didAddParticipant participant: Participant
    ) {
        actions.append(.add(participant))
    }

    func rosterList(
        _ rosterList: RosterList,
        didUpdateParticipant participant: Participant
    ) {
        actions.append(.update(participant))
    }

    func rosterList(
        _ rosterList: RosterList,
        didRemoveParticipant participant: Participant
    ) {
        actions.append(.remove(participant))
    }

    func rosterList(
        _ rosterList: RosterList,
        didReloadParticipants participants: [Participant]
    ) {
        actions.append(.reload(participants))
    }
}
