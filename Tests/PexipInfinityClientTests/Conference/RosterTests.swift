//
// Copyright 2022-2023 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import XCTest
import Combine
@testable import PexipInfinityClient

// swiftlint:disable type_body_length
final class RosterTests: XCTestCase {
    private let currentParticipantId = UUID().uuidString
    private let currentParticipantName = "My User"
    private var roster: Roster!
    private var delegate: RosterDelegateMock!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        delegate = RosterDelegateMock()
        roster = Roster(
            currentParticipantId: currentParticipantId,
            currentParticipantName: currentParticipantName,
            participants: [],
            avatarURL: { id in
                Participant.avatarURL(id: id)
            }
        )
        roster.delegate = delegate
    }

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - Tests

    func testInit() {
        let participants = [
            Participant.stub(withId: UUID().uuidString, displayName: "GuestA"),
            Participant.stub(withId: UUID().uuidString, displayName: "GuestB")
        ]
        roster = Roster(
            currentParticipantId: currentParticipantId,
            currentParticipantName: currentParticipantName,
            participants: participants,
            avatarURL: { _ in nil }
        )
        XCTAssertEqual(roster.participants, participants)
        XCTAssertEqual(roster.currentParticipantId, currentParticipantId)
        XCTAssertEqual(roster.currentParticipantName, currentParticipantName)
    }

    func testIsCurrentParticipant() {
        let participantA = Participant.stub(
            withId: currentParticipantId,
            displayName: "Test"
        )
        XCTAssertTrue(roster.isCurrentParticipant(participantA))

        let participantB = Participant.stub(
            withId: UUID().uuidString,
            displayName: "Test"
        )
        XCTAssertFalse(roster.isCurrentParticipant(participantB))
    }

    func testCurrentParticipantAvatarURL() {
        XCTAssertEqual(
            roster.currentParticipantAvatarURL,
            Participant.avatarURL(id: currentParticipantId)
        )
    }

    func testAvatarURLForParticipant() {
        let participant = Participant.stub(displayName: "Test")
        XCTAssertEqual(
            roster.avatarURL(for: participant),
            Participant.avatarURL(id: participant.id)
        )
    }

    func testCurrentParticipantNameUpdate() async {
        XCTAssertEqual(roster.currentParticipantName, "My User")

        // 1. Change currentParticipantName on add
        await roster.addParticipant(
            .stub(withId: currentParticipantId, displayName: "My User 1")
        )
        XCTAssertEqual(roster.currentParticipantName, "My User 1")

        // 1. Change currentParticipantName on update
        await roster.updateParticipant(
            .stub(withId: currentParticipantId, displayName: "My User 2")
        )
        XCTAssertEqual(roster.currentParticipantName, "My User 2")
    }

    func testSetSyncing() async {
        // 1. Prepare test data
        let participantsToAdd = [
            Participant.stub(displayName: "Guest1"),
            Participant.stub(displayName: "Guest2"),
            Participant.stub(displayName: "Guest3")
        ]
        let participantsToUpdate = [
            Participant.stub(
                withId: participantsToAdd[1].id,
                displayName: "Updated Guest2"
            )
        ]
        let participantsToRemove = [participantsToAdd[0]]
        let expectedParticipants = [
            participantsToUpdate[0],
            participantsToAdd[2]
        ]
        var publishCount = 0
        var publishedParticipants = [[Participant]]()
        var events = [ParticipantEvent]()

        // 2. Subscibe to updates
        roster.$participants.sink { participants in
            publishedParticipants.append(participants)
            publishCount += 1
        }.store(in: &cancellables)

        roster.eventPublisher.sink(receiveValue: { event in
            events.append(event)
        }).store(in: &cancellables)

        // 3. Start syncing
        await roster.setSyncing(true)

        for participant in participantsToAdd {
            await roster.addParticipant(participant)
        }

        for participant in participantsToUpdate {
            await roster.updateParticipant(participant)
        }

        for participant in participantsToRemove {
            await roster.removeParticipant(withId: participant.id)
        }

        await roster.setSyncing(false)

        // 4. Assert

        XCTAssertEqual(roster.participants, expectedParticipants)
        XCTAssertEqual(delegate.events, [.reloaded(expectedParticipants)])
        XCTAssertEqual(delegate.events, events)
        XCTAssertEqual(publishedParticipants, [[], expectedParticipants])
        XCTAssertEqual(publishCount, 2)
    }

    func testAddParticipant() async {
        // 1. Prepare test data
        let participantA = Participant.stub(displayName: "GuestA")
        let participantB = Participant.stub(displayName: "GuestB")
        var publishCount = 0
        var publishedParticipants = [[Participant]]()
        var events = [ParticipantEvent]()
        let expectedParticipants = [
            participantA,
            participantB
        ]

        // 2. Subscibe to updates
        roster.$participants.sink { participants in
            publishedParticipants.append(participants)
            publishCount += 1
        }.store(in: &cancellables)

        roster.eventPublisher.sink(receiveValue: { event in
            events.append(event)
        }).store(in: &cancellables)

        // 3. Add participant
        await roster.addParticipant(participantA)
        await roster.addParticipant(participantB)

        // 4. Assert
        XCTAssertEqual(roster.participants, expectedParticipants)
        XCTAssertEqual(delegate.events, events)
        XCTAssertEqual(
            delegate.events,
            [.added(participantA), .added(participantB)]
        )
        XCTAssertEqual(
            publishedParticipants,
            [
                [],
                [participantA],
                [participantA, participantB]
            ]
        )
        XCTAssertEqual(publishCount, 3)
    }

    func testUpdateParticipant() async {
        // 1. Prepare test data
        let participantA = Participant.stub(displayName: "GuestA")
        let participantB = Participant.stub(withId: participantA.id, displayName: "GuestB")
        var publishCount = 0
        var publishedParticipants = [[Participant]]()
        let expectedParticipants = [participantB]
        var events = [ParticipantEvent]()

        // 2. Subscibe to updates
        roster.$participants.sink { participants in
            publishedParticipants.append(participants)
            publishCount += 1
        }.store(in: &cancellables)

        roster.eventPublisher.sink(receiveValue: { event in
            events.append(event)
        }).store(in: &cancellables)

        // 3. Add and update participant
        await roster.addParticipant(participantA)
        await roster.updateParticipant(participantB)

        // 4. Assert
        XCTAssertEqual(roster.participants, expectedParticipants)
        XCTAssertEqual(delegate.events, events)
        XCTAssertEqual(
            delegate.events,
            [.added(participantA), .updated(participantB)]
        )
        XCTAssertEqual(
            publishedParticipants,
            [[], [participantA], [participantB]]
        )
        XCTAssertEqual(publishCount, 3)
    }

    func testUpdateParticipantWithNotExisingId() async {
        // 1. Prepare test data
        let participantA = Participant.stub(displayName: "GuestA")
        let participantB = Participant.stub(displayName: "GuestB")
        var publishCount = 0
        var publishedParticipants = [[Participant]]()
        let expectedParticipants = [participantA]
        var events = [ParticipantEvent]()

        // 2. Subscibe to updates
        roster.$participants.sink { participants in
            publishedParticipants.append(participants)
            publishCount += 1
        }.store(in: &cancellables)

        roster.eventPublisher.sink(receiveValue: { event in
            events.append(event)
        }).store(in: &cancellables)

        // 3. Add and update participant
        await roster.addParticipant(participantA)
        await roster.updateParticipant(participantB)

        // 4. Assert
        XCTAssertEqual(roster.participants, expectedParticipants)
        XCTAssertEqual(delegate.events, [.added(participantA)])
        XCTAssertEqual(delegate.events, events)
        XCTAssertEqual(publishedParticipants, [[], [participantA]])
        XCTAssertEqual(publishCount, 2)
    }

    func testRemoveParticipant() async {
        // 1. Prepare test data
        let participantA = Participant.stub(displayName: "GuestA")
        let participantB = Participant.stub(displayName: "GuestB")
        var publishCount = 0
        var publishedParticipants = [[Participant]]()
        let expectedParticipants = [participantB]
        var events = [ParticipantEvent]()

        // 2. Subscibe to updates
        roster.$participants.sink { participants in
            publishedParticipants.append(participants)
            publishCount += 1
        }.store(in: &cancellables)

        roster.eventPublisher.sink(receiveValue: { event in
            events.append(event)
        }).store(in: &cancellables)

        // 3. Add and remove participants
        await roster.addParticipant(participantA)
        await roster.addParticipant(participantB)
        await roster.removeParticipant(withId: participantA.id)

        // 4. Assert
        XCTAssertEqual(roster.participants, expectedParticipants)
        XCTAssertEqual(events, delegate.events)
        XCTAssertEqual(
            delegate.events,
            [.added(participantA), .added(participantB), .deleted(participantA)]
        )
        XCTAssertEqual(
            publishedParticipants,
            [
                [],
                [participantA],
                [participantA, participantB],
                [participantB]
            ]
        )
        XCTAssertEqual(publishCount, 4)
    }

    func testRemoveParticipantWithNotExistingId() async {
        // 1. Prepare test data
        let participant = Participant.stub(displayName: "GuestA")
        var publishCount = 0
        var publishedParticipants = [[Participant]]()
        let expectedParticipants = [participant]
        var events = [ParticipantEvent]()

        // 2. Subscibe to updates
        roster.$participants.sink { participants in
            publishedParticipants.append(participants)
            publishCount += 1
        }.store(in: &cancellables)

        roster.eventPublisher.sink(receiveValue: { event in
            events.append(event)
        }).store(in: &cancellables)

        // 3. Add and remove participants
        await roster.addParticipant(participant)
        await roster.removeParticipant(withId: UUID().uuidString)

        // 4. Assert
        XCTAssertEqual(roster.participants, expectedParticipants)
        XCTAssertEqual(delegate.events, [.added(participant)])
        XCTAssertEqual(events, delegate.events)
        XCTAssertEqual(publishedParticipants, [[], [participant]])
        XCTAssertEqual(publishCount, 2)
    }

    func testClear() async {
        // 1. Prepare test data
        let participant = Participant.stub(displayName: "GuestA")
        var publishCount = 0
        var publishedParticipants = [[Participant]]()
        var events = [ParticipantEvent]()

        // 2. Subscibe to updates
        roster.$participants.sink { participants in
            publishedParticipants.append(participants)
            publishCount += 1
        }.store(in: &cancellables)

        roster.eventPublisher.sink(receiveValue: { event in
            events.append(event)
        }).store(in: &cancellables)

        // 3. Add and clear participants
        await roster.addParticipant(participant)
        await roster.clear()

        // 4. Assert
        XCTAssertTrue(roster.participants.isEmpty)
        XCTAssertEqual(delegate.events, [.added(participant), .reloaded([])])
        XCTAssertEqual(
            publishedParticipants,
            [[], [participant], []]
        )
        XCTAssertEqual(publishCount, 3)
    }
}

// MARK: - Mocks

private final class RosterDelegateMock: RosterDelegate {
    private(set) var events = [ParticipantEvent]()

    func roster(_ roster: Roster, didReceiveParticipantEvent event: ParticipantEvent) {
        events.append(event)
    }
}
