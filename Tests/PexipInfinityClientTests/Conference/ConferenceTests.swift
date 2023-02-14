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
import PexipCore
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
    private var signalingChannel: SignalingChannelMock!
    private var splashScreenService: SplashScreenServiceMock!
    private var roster: Roster!
    private var chat: Chat!
    private var delegateMock: ConferenceDelegateMock!
    private var eventSender: TestResultSender<ConferenceEvent>!
    private var isEventSourceTerminated = false
    private var leaveExpectation: XCTestExpectation?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Setup

    // swiftlint:disable function_body_length
    override func setUp() async throws {
        try await super.setUp()

        let token = ConferenceToken.randomToken()
        tokenStore = TokenStore<ConferenceToken>(token: token)
        tokenRefreshTask = TokenRefreshTaskMock()
        liveCaptionsService = LiveCaptionsServiceMock()
        splashScreenService = SplashScreenServiceMock()
        delegateMock = ConferenceDelegateMock()
        eventSender = TestResultSender()
        signalingChannel = SignalingChannelMock()

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

        chat = Chat(
            senderName: "Test",
            senderId: UUID().uuidString,
            sendMessage: { _ in true }
        )

        conference = DefaultConference(
            connection: InfinityConnection(
                tokenRefreshTask: tokenRefreshTask,
                eventSource: eventSource
            ),
            tokenStore: tokenStore,
            signalingChannel: signalingChannel,
            roster: roster,
            splashScreenService: splashScreenService,
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

    func testSetDataReceiverOnInit() {
        XCTAssertNotNil(conference.signalingChannel.data?.receiver)
        XCTAssertTrue(conference.signalingChannel.data?.receiver === conference)
    }

    func testFailureEventOnTokenRefreshError() {
        let error = URLError(.unknown)
        var receivedEvents = [ConferenceClientEvent]()

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
        let conferenceStatus = ConferenceStatus.stub()
        let liveCaptions = LiveCaptions(data: "Test", isFinal: true, sentAt: nil)
        let presentationStart = PresentationStartEvent(
            presenterName: "Test",
            presenterUri: ""
        )
        let callDisconnect = CallDisconnectEvent(callId: "id", reason: "Test")
        let clientDisconnect = ClientDisconnectEvent(reason: "Test")
        let refer = ReferEvent(token: UUID().uuidString, alias: "test@example.com")
        let events: [ConferenceEvent] = [
            .splashScreen(nil),
            .conferenceUpdate(conferenceStatus),
            .liveCaptions(liveCaptions),
            .presentationStart(presentationStart),
            .presentationStop, // First presentationStop event should be skipped.
            .presentationStop,
            .callDisconnected(callDisconnect),
            .clientDisconnected(clientDisconnect),
            .peerDisconnected,
            .refer(refer)
        ]
        var receivedEvents = [ConferenceClientEvent]()

        // 3. Send events
        wait(
            for: { expectation in
                conference.eventPublisher.sink { event in
                    receivedEvents.append(event)
                    if receivedEvents.count == 9 {
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
        XCTAssertEqual(
            receivedEvents,
            [
                .splashScreen(nil),
                .conferenceUpdate(conferenceStatus),
                .liveCaptions(liveCaptions),
                .presentationStart(presentationStart),
                .presentationStop,
                .callDisconnected(callDisconnect),
                .clientDisconnected(clientDisconnect),
                .peerDisconnected,
                .refer(refer)
            ]
        )
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
            .splashScreen(nil),
            .presentationStop
        ]
        var receivedEvents = [ConferenceClientEvent]()

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
        XCTAssertEqual(receivedEvents, [.splashScreen(nil), .presentationStop])
    }

    func testHandleSplashScreenEvent() {
        // 1. Subscribe to events
        conference.receiveEvents()

        // 2. Prepare
        let key = "direct_media_welcome"
        let splashScreen = SplashScreen(
            layoutType: "direct_media",
            background: .init(path: "background.jpg"),
            elements: []
        )
        splashScreenService.splashScreens = [key: splashScreen]

        // 3. Send event and assert
        wait(
            for: { expectation in
                conference.eventPublisher.sink { event in
                    Task { @MainActor [weak self] in
                        switch event {
                        case .splashScreen(let event):
                            XCTAssertEqual(event, splashScreen)
                            XCTAssertNotNil(self?.conference.splashScreens)
                            XCTAssertEqual(
                                self?.conference.splashScreens,
                                self?.splashScreenService.splashScreens
                            )
                            expectation.fulfill()
                        default:
                            XCTFail("Unexpected event")
                        }
                    }
                }.store(in: &cancellables)
            },
            after: {
                eventSender.send(.success(.splashScreen(.init(key: key))))
            }
        )
    }

    func testHandleNewOfferEvent() {
        // 1. Subscribe to events
        conference.receiveEvents()

        // 2. Prepare
        let expectedOffer = UUID().uuidString

        // 3. Send event and assert
        wait(
            for: { expectation in
                signalingChannel.eventPublisher.sink { event in
                    Task { @MainActor in
                        switch event {
                        case .newOffer(let offer):
                            XCTAssertEqual(offer, expectedOffer)
                            expectation.fulfill()
                        default:
                            XCTFail("Unexpected event")
                        }
                    }
                }.store(in: &cancellables)
            },
            after: {
                eventSender.send(.success(.newOffer(NewOfferMessage(sdp: expectedOffer))))
            }
        )
    }

    func testHandleUpdateSdpEvent() {
        // 1. Subscribe to events
        conference.receiveEvents()

        // 2. Prepare
        let expectedOffer = UUID().uuidString

        // 3. Send event and assert
        wait(
            for: { expectation in
                signalingChannel.eventPublisher.sink { event in
                    Task { @MainActor in
                        switch event {
                        case .newOffer(let offer):
                            XCTAssertEqual(offer, expectedOffer)
                            expectation.fulfill()
                        default:
                            XCTFail("Unexpected event")
                        }
                    }
                }.store(in: &cancellables)
            },
            after: {
                eventSender.send(.success(.updateSdp(UpdateSdpMessage(sdp: expectedOffer))))
            }
        )
    }

    func testHandleNewCandidateEvent() {
        // 1. Subscribe to events
        conference.receiveEvents()

        // 2. Prepare
        let expectedCandidate = IceCandidate(
            candidate: UUID().uuidString,
            mid: "1",
            ufrag: nil,
            pwd: nil
        )

        // 3. Send event and assert
        wait(
            for: { expectation in
                signalingChannel.eventPublisher.sink { event in
                    Task { @MainActor in
                        switch event {
                        case let .newCandidate(candidate, mid):
                            XCTAssertEqual(candidate, expectedCandidate.candidate)
                            XCTAssertEqual(mid, expectedCandidate.mid)
                            expectation.fulfill()
                        default:
                            XCTFail("Unexpected event")
                        }
                    }
                }.store(in: &cancellables)
            },
            after: {
                eventSender.send(.success(.newCandidate(expectedCandidate)))
            }
        )
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
        let message = ChatMessage(
            senderName: "Name",
            senderId: UUID().uuidString,
            payload: "Test"
        )
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
        let idA = UUID().uuidString
        let idB = UUID().uuidString
        let participantA = Participant.stub(withId: idA, displayName: "A")
        let participantB = Participant.stub(withId: idB, displayName: "B")
        let participantC = Participant.stub(withId: idA, displayName: "C")

        // 3. Send events and assert
        wait(
            for: { expectation in
                conference.roster.eventPublisher.sink { event in
                    Task { @MainActor in
                        switch event {
                        case .reloaded(let participants):
                            XCTAssertEqual(participants, [participantC])
                            expectation.fulfill()
                        default:
                            XCTFail("Invalid event")
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
                    .success(.callDisconnected(.init(
                        callId: UUID().uuidString,
                        reason: "Unknown")
                    ))
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
            await roster.addParticipant(.stub(
                withId: UUID().uuidString,
                displayName: "Test"
            ))
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
            await roster.addParticipant(.stub(
                withId: UUID().uuidString,
                displayName: "Test"
            ))
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

    func testReceiveDataWithoutDirectMedia() async throws {
        let result = try await conference.receive(Data())
        XCTAssertFalse(result)
    }

    func testReceiveDataWithDirectMedia() throws {
        let status = ConferenceStatus.stub(directMedia: true)
        let message = ChatMessage(
            senderName: "Name",
            senderId: UUID().uuidString,
            payload: "Test"
        )
        let dataMessage = DataMessage.text(message)
        let data = try JSONEncoder().encode(dataMessage)

        // 1. Subscribe to events
        conference.receiveEvents()

        // 2. Send event and assert
        wait(
            for: { expectation in
                conference.eventPublisher.sink { event in
                    switch event {
                    case .conferenceUpdate:
                        Task { [weak self] in
                            let result = try await self?.conference.receive(data)
                            XCTAssertTrue(result == true)
                        }
                    default:
                        break
                    }
                }.store(in: &cancellables)

                chat.publisher.sink { (newMessage: ChatMessage) in
                    XCTAssertEqual(newMessage.senderName, message.senderName)
                    XCTAssertEqual(newMessage.senderId, message.senderId)
                    XCTAssertEqual(newMessage.type, message.type)
                    XCTAssertEqual(newMessage.payload, message.payload)
                    expectation.fulfill()
                }.store(in: &cancellables)
            },
            after: {
                eventSender.send(.success(.conferenceUpdate(status)))
            }
        )
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

final class SignalingChannelMock: SignalingChannel, SignalingEventSender {
    var callId: String?
    let iceServers = [PexipCore.IceServer]()
    var data: DataChannel? = DataChannel(id: 11)
    var eventPublisher: AnyPublisher<SignalingEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    private let eventSubject = PassthroughSubject<SignalingEvent, Never>()

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

    func sendEvent(_ event: SignalingEvent) {
        eventSubject.send(event)
    }
}

private final class ConferenceDelegateMock: ConferenceDelegate {
    private(set) var events = [ConferenceClientEvent]()

    func conference(
        _ conference: Conference,
        didReceiveEvent event: ConferenceClientEvent
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

private final class SplashScreenServiceMock: SplashScreenService {
    var splashScreens = [String: SplashScreen]()

    func splashScreens(token: ConferenceToken) async throws -> [String: SplashScreen] {
        return splashScreens
    }

    func backgroundURL(
        for background: SplashScreen.Background,
        token: ConferenceToken
    ) -> URL? {
        return nil
    }
}

private extension ConferenceStatus {
    static func stub(
        liveCaptionsAvailable: Bool = true,
        directMedia: Bool = false
    ) -> ConferenceStatus {
        ConferenceStatus(
            started: true,
            locked: false,
            allMuted: false,
            guestsMuted: false,
            presentationAllowed: true,
            directMedia: directMedia,
            liveCaptionsAvailable: liveCaptionsAvailable
        )
    }
}