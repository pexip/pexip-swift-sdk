import XCTest
import Combine
import TestHelpers
@testable import PexipInfinityClient

// swiftlint:disable file_length
// swiftlint:disable type_body_length
final class ConferenceTests: XCTestCase {
    private var conference: DefaultConference!
    private var tokenStore: TokenStore<ConferenceToken>!
    private var tokenRefreshTask: TokenRefreshTaskMock!
    private var eventSource: InfinityEventSource<ConferenceEvent>!
    private var liveCaptionsService: LiveCaptionsServiceMock!
    private var roster: Roster!
    private var chat: Chat!
    private var delegateMock: ConferenceDelegateMock!
    private var eventSender: TestResultSender<ConferenceEvent>!
    private var isEventSourceTerminated = false
    private var leaveExpectation: XCTestExpectation?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Setup

    override func setUp() async throws {
        try await super.setUp()

        let token = ConferenceToken.randomToken()
        tokenStore = TokenStore<ConferenceToken>(token: token)
        tokenRefreshTask = TokenRefreshTaskMock()
        liveCaptionsService = LiveCaptionsServiceMock()
        delegateMock = ConferenceDelegateMock()
        eventSender = TestResultSender()

        let stream = AsyncThrowingStream<ConferenceEvent, Error> { [weak self] continuation in
            continuation.onTermination = { @Sendable [weak self] _ in
                self?.isEventSourceTerminated = true
                self?.leaveExpectation?.fulfill()
            }
            self?.eventSender.setHandler { result in
                do {
                    continuation.yield(try result.get())
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
        eventSource = InfinityEventSource(
            name: "Conference",
            stream: { stream }
        )

        roster = Roster(
            currentParticipantId: token.participantId,
            currentParticipantName: token.displayName,
            avatarURL: { _ in nil }
        )

        chat = Chat(senderName: "Test", senderId: UUID(), sendMessage: { _ in true })

        conference = DefaultConference(
            connection: InfinityConnection(
                tokenRefreshTask: tokenRefreshTask,
                eventSource: eventSource
            ),
            tokenStore: tokenStore,
            signalingChannel: SignalingChannelMock(),
            roster: roster,
            liveCaptionsService: liveCaptionsService,
            chat: chat,
            logger: nil
        )

        conference.delegate = delegateMock
    }

    override func tearDown() {
        isEventSourceTerminated = false
        leaveExpectation = nil
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - Tests

    func testFailureEventOnTokenRefreshError() {
        let error = URLError(.unknown)
        var receivedEvents = [ConferenceEvent]()

        // 1. Wait for events
        wait(
            for: { expectation in
                conference.eventPublisher.sink { event in
                    receivedEvents.append(event)
                    expectation.fulfill()
                }.store(in: &cancellables)
            },
            after: {
                Task(priority: .low) {
                    tokenRefreshTask.subject.send(.failed(error))
                }
            }
        )

        // 2. Assert
        XCTAssertEqual(receivedEvents.count, 1)
        XCTAssertEqual(delegateMock.events, receivedEvents)

        switch receivedEvents.first {
        case .failure(let event):
            XCTAssertEqual(event.error as? URLError, error)
        default:
            XCTFail("Invalid event type")
        }
    }

    func testReceiveEvents() {
        // 1. Subscribe to events
        XCTAssertTrue(conference.receiveEvents())

        // 2. Prepare
        let events: [ConferenceEvent] = [
            .participantSyncBegin,
            .participantSyncEnd
        ]
        var receivedEvents = [ConferenceEvent]()

        // 3. Send events
        wait(
            for: { expectation in
                conference.eventPublisher.sink { event in
                    receivedEvents.append(event)
                    if receivedEvents.count == 3 {
                        expectation.fulfill()
                    }
                }.store(in: &cancellables)
            },
            after: {
                for event in events {
                    eventSender.send(.success(event))
                }
                eventSender.send(.failure(InfinityTokenError.tokenExpired))
            }
        )

        // 4. Assert
        XCTAssertEqual(delegateMock.events, receivedEvents)
        XCTAssertEqual(receivedEvents.count, 3)
        XCTAssertEqual(receivedEvents[0], events[0])
        XCTAssertEqual(receivedEvents[1], events[1])

        switch receivedEvents[2] {
        case .failure(let event):
            XCTAssertEqual(event.error as? InfinityTokenError, .tokenExpired)
        default:
            XCTFail("Invalid event type")
        }
    }

    func testReceiveEventsWhenAlreadySubscribed() {
        XCTAssertTrue(conference.receiveEvents())
        XCTAssertFalse(conference.receiveEvents())
    }

    func testReceiveEventsAfterEventSourceError() {
        // 1. Subscribe to events
        XCTAssertTrue(conference.receiveEvents())

        // 2. Send failure event
        wait(
            for: { expectation in
                conference.eventPublisher.sink { _ in
                    expectation.fulfill()
                }.store(in: &cancellables)
            },
            after: {
                eventSender.send(.failure(URLError(.unknown)))
            }
        )

        // 3. Resubscribe to events
        XCTAssertTrue(conference.receiveEvents())
    }

    func testSkipFirstPresentationStop() {
        // 1. Subscribe to events
        XCTAssertTrue(conference.receiveEvents())

        // 2. Prepare
        let events: [ConferenceEvent] = [
            .presentationStop,
            .participantSyncBegin,
            .presentationStop
        ]
        var receivedEvents = [ConferenceEvent]()

        // 3. Send events
        wait(
            for: { expectation in
                conference.eventPublisher.sink { event in
                    receivedEvents.append(event)
                    if receivedEvents.count == 2 {
                        expectation.fulfill()
                    }
                }.store(in: &cancellables)
            },
            after: {
                for event in events {
                    eventSender.send(.success(event))
                }
            }
        )

        // 4. Assert
        XCTAssertEqual(delegateMock.events, receivedEvents)
        XCTAssertEqual(receivedEvents, [.participantSyncBegin, .presentationStop])
    }

    func testHandleConferenceUpdateEvent() {
        let status = ConferenceStatus.stub()

        // 1. Subscribe to events
        conference.receiveEvents()

        // 2. Send event and assert
        wait(
            for: { expectation in
                conference.eventPublisher.sink { _ in
                    Task { [weak self] in
                        let conferenceStatus = self?.conference.status
                        XCTAssertEqual(conferenceStatus, status)
                        expectation.fulfill()
                    }
                }.store(in: &cancellables)
            },
            after: {
                eventSender.send(.success(.conferenceUpdate(status)))
            }
        )
    }

    func testHandleMessageReceivedEvent() {
        // 1. Subscribe to events
        conference.receiveEvents()

        // 2. Prepare
        let message = ChatMessage(senderName: "Name", senderId: UUID(), payload: "Test")
        let event = ConferenceEvent.messageReceived(message)

        // 3. Send event and assert
        wait(
            for: { expectation in
                chat.publisher.sink { (newMessage: ChatMessage) in
                    XCTAssertEqual(newMessage, message)
                    expectation.fulfill()
                }.store(in: &cancellables)
            },
            after: {
                eventSender.send(.success(event))
            }
        )
    }

    func testHandleParticipantEvents() {
        // 1. Subscribe to events
        conference.receiveEvents()

        // 2. Prepare
        let idA = UUID()
        let idB = UUID()
        let participantA = Participant.stub(withId: idA, displayName: "A")
        let participantB = Participant.stub(withId: idB, displayName: "B")
        let participantC = Participant.stub(withId: idA, displayName: "C")

        // 3. Send events and assert
        wait(
            for: { expectation in
                conference.eventPublisher.sink { event in
                    Task { @MainActor in
                        switch event {
                        case .participantSyncBegin:
                            let isSyncing = await self.roster.isSyncing
                            XCTAssertTrue(isSyncing)
                        case .participantSyncEnd:
                            let isSyncing = await self.roster.isSyncing
                            XCTAssertFalse(isSyncing)
                            XCTAssertEqual(self.roster.participants, [participantC])
                            expectation.fulfill()
                        case .participantCreate, .participantUpdate, .participantDelete:
                            break
                        default:
                            XCTFail("Unexpected event")
                        }
                    }
                }.store(in: &cancellables)
            },
            after: {
                eventSender.send(.success(.participantSyncBegin))
                eventSender.send(.success(.participantCreate(participantA)))
                eventSender.send(.success(.participantCreate(participantB)))
                eventSender.send(.success(.participantUpdate(participantC)))
                eventSender.send(.success(.participantDelete(.init(id: idB))))
                eventSender.send(.success(.participantSyncEnd))
            }
        )
    }

    func testHandleClientDisconnectedEvent() {
        // 1. Subscribe to events
        XCTAssertTrue(conference.receiveEvents())

        // 2. Send events
        wait(
            for: { expectation in
                conference.eventPublisher.sink { event in
                    if case .failure = event {
                        expectation.fulfill()
                    }
                }.store(in: &cancellables)
            },
            after: {
                eventSender.send(
                    .success(.callDisconnected(.init(callId: UUID(), reason: "Unknown")))
                )
                eventSender.send(
                    .success(.clientDisconnected(.init(reason: "Unknown")))
                )
                eventSender.send(.failure(URLError(.unknown)))
            }
        )

        // 3. Assert
        XCTAssertTrue(conference.isClientDisconnected)
        XCTAssertFalse(conference.receiveEvents())
    }

    func testToggleLiveCaptions() {
        // 1. Subscribe to events
        conference.receiveEvents()

        // 2. Send event and assert
        wait(
            for: { expectation in
                conference.eventPublisher.sink { _ in
                    Task { [weak self] in
                        let result1 = try await self?.conference.toggleLiveCaptions(true)
                        XCTAssertTrue(result1 == true)
                        XCTAssertTrue(self?.liveCaptionsService.flag == true)

                        let result2 = try await self?.conference.toggleLiveCaptions(false)
                        XCTAssertTrue(result2 == true)
                        XCTAssertTrue(self?.liveCaptionsService.flag == false)

                        expectation.fulfill()
                    }
                }.store(in: &cancellables)
            },
            after: {
                eventSender.send(.success(
                    .conferenceUpdate(.stub(liveCaptionsAvailable: true))
                ))
            }
        )
    }

    func testToggleLiveCaptionsWithNoConferenceStatus() async throws {
        let result = try await conference.toggleLiveCaptions(true)
        XCTAssertFalse(result)
        XCTAssertNil(liveCaptionsService.flag)
    }

    func testToggleLiveCaptionsWhenNotAvailable() {
        // 1. Subscribe to events
        conference.receiveEvents()

        // 2. Send event and assert
        wait(
            for: { expectation in
                conference.eventPublisher.sink { _ in
                    Task { [weak self] in
                        // 4. Assert
                        let result = try await self?.conference.toggleLiveCaptions(true)
                        XCTAssertTrue(result == false)
                        XCTAssertNil(self?.liveCaptionsService.flag)

                        expectation.fulfill()
                    }
                }.store(in: &cancellables)
            },
            after: {
                eventSender.send(.success(
                    .conferenceUpdate(.stub(liveCaptionsAvailable: false))
                ))
            }
        )
    }

    func testLeave() {
        leaveExpectation = expectation(description: "Leave expectation")

        // 1. Subscribe to events
        conference.receiveEvents()

        // 2. Leave
        Task {
            await roster.addParticipant(.stub(withId: UUID(), displayName: "Test"))
            await conference.leave()
        }

        wait(for: [leaveExpectation!], timeout: 0.1)

        // 3. Assert
        let assertExpectation = expectation(description: "Assert expectation")

        Task { @MainActor in
            XCTAssertFalse(tokenRefreshTask.isCancelCalled)
            XCTAssertTrue(tokenRefreshTask.isCancelAndReleaseCalled)
            XCTAssertTrue(isEventSourceTerminated)
            XCTAssertTrue(roster.participants.isEmpty)
            assertExpectation.fulfill()
        }

        wait(for: [assertExpectation], timeout: 0.1)
    }

    func testLeaveWhenDisconnected() {
        leaveExpectation = expectation(description: "Leave expectation")

        // 1. Subscribe to events
        conference.receiveEvents()

        // 2. Send events
        wait(
            for: { expectation in
                conference.eventPublisher.sink { _ in
                    expectation.fulfill()
                }.store(in: &cancellables)
            },
            after: {
                eventSender.send(
                    .success(.clientDisconnected(.init(reason: "Unknown")))
                )
            }
        )

        // 3. Leave
        Task {
            await roster.addParticipant(.stub(withId: UUID(), displayName: "Test"))
            await conference.leave()
        }

        wait(for: [leaveExpectation!], timeout: 0.1)

        // 4. Assert
        let assertExpectation = expectation(description: "Assert expectation")

        Task { @MainActor in
            XCTAssertTrue(tokenRefreshTask.isCancelCalled)
            XCTAssertFalse(tokenRefreshTask.isCancelAndReleaseCalled)
            XCTAssertTrue(isEventSourceTerminated)
            XCTAssertTrue(roster.participants.isEmpty)
            assertExpectation.fulfill()
        }

        wait(for: [assertExpectation], timeout: 0.1)
    }

    func testDeinit() {
        leaveExpectation = expectation(description: "Leave expectation")

        // 1. Subscribe to events
        conference.receiveEvents()

        // 2. Deinit
        Task { @MainActor in
            conference = nil
        }

        wait(for: [leaveExpectation!], timeout: 0.1)

        // 3. Assert
        let assertExpectation = expectation(description: "Assert expectation")

        Task { @MainActor in
            XCTAssertTrue(tokenRefreshTask.isCancelCalled)
            XCTAssertTrue(tokenRefreshTask.isCancelAndReleaseCalled)
            XCTAssertTrue(isEventSourceTerminated)
            assertExpectation.fulfill()
        }

        wait(for: [assertExpectation], timeout: 0.1)
    }

    func testDeinitWhenDisconnected() {
        leaveExpectation = expectation(description: "Leave expectation")

        // 1. Subscribe to events
        conference.receiveEvents()

        // 2. Send events
        wait(
            for: { expectation in
                conference.eventPublisher.sink { _ in
                    expectation.fulfill()
                }.store(in: &cancellables)
            },
            after: {
                eventSender.send(
                    .success(.clientDisconnected(.init(reason: "Unknown")))
                )
            }
        )

        // 3. Deinit
        Task { @MainActor in
            conference = nil
        }

        wait(for: [leaveExpectation!], timeout: 0.1)

        // 4. Assert
        let assertExpectation = expectation(description: "Assert expectation")

        Task { @MainActor in
            XCTAssertTrue(tokenRefreshTask.isCancelCalled)
            XCTAssertFalse(tokenRefreshTask.isCancelAndReleaseCalled)
            XCTAssertTrue(isEventSourceTerminated)
            assertExpectation.fulfill()
        }

        wait(for: [assertExpectation], timeout: 0.1)
    }
}

// MARK: - Mocks

private final class ConferenceDelegateMock: ConferenceDelegate {
    private(set) var events = [ConferenceEvent]()

    func conference(
        _ conference: Conference,
        didReceiveEvent event: ConferenceEvent
    ) {
        events.append(event)
    }
}

private final class LiveCaptionsServiceMock: LiveCaptionsService {
    private(set) var token: ConferenceToken?
    private(set) var flag: Bool?

    func showLiveCaptions(token: PexipInfinityClient.ConferenceToken) async throws {
        self.token = token
        flag = true
    }

    func hideLiveCaptions(token: PexipInfinityClient.ConferenceToken) async throws {
        self.token = token
        flag = false
    }
}

private final class SignalingChannelMock: SignalingChannel {
    var callId: UUID?
    let iceServers = [IceServer]()

    func sendOffer(
        callType: String,
        description: String,
        presentationInMain: Bool
    ) async throws -> String? {
        return ""
    }

    func sendAnswer(_ description: String) async throws {}
    func addCandidate(_ candidate: String, mid: String?) async throws {}

    func dtmf(signals: DTMFSignals) async throws -> Bool {
        return false
    }

    func muteVideo(_ muted: Bool) async throws -> Bool {
        return false
    }

    func muteAudio(_ muted: Bool) async throws -> Bool {
        return false
    }

    func takeFloor() async throws -> Bool {
        return false
    }

    func releaseFloor() async throws -> Bool {
        return false
    }
}

private extension ConferenceStatus {
    static func stub(liveCaptionsAvailable: Bool = true) -> ConferenceStatus {
        ConferenceStatus(
            started: true,
            locked: false,
            allMuted: false,
            guestsMuted: false,
            presentationAllowed: true,
            directMedia: false,
            liveCaptionsAvailable: liveCaptionsAvailable
        )
    }
}
