//
// Copyright 2022 Pexip AS
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
import TestHelpers
@testable import PexipInfinityClient

final class RegistrationTests: XCTestCase {
    private var registration: Registration!
    private var tokenRefreshTask: TokenRefreshTaskMock!
    private var eventSource: InfinityEventSource<RegistrationEvent>!
    private var delegateMock: RegistrationDelegateMock!
    private var eventSender: TestResultSender<RegistrationEvent>!
    private var cancellables = Set<AnyCancellable>()
    private var isEventSourceTerminated = false
    private var cancelExpectation: XCTestExpectation?

    // MARK: - Setup

    override func setUp() async throws {
        try await super.setUp()
        isEventSourceTerminated = false
        tokenRefreshTask = TokenRefreshTaskMock()
        delegateMock = RegistrationDelegateMock()
        eventSender = TestResultSender()

        let stream = AsyncThrowingStream<RegistrationEvent, Error> { [weak self] continuation in
            continuation.onTermination = { @Sendable [weak self] _ in
                self?.isEventSourceTerminated = true
                self?.cancelExpectation?.fulfill()
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
            name: "Registration",
            stream: { stream }
        )

        registration = DefaultRegistration(
            connection: InfinityConnection(
                tokenRefreshTask: tokenRefreshTask,
                eventSource: eventSource
            ),
            logger: nil
        )
        registration.delegate = delegateMock
    }

    // MARK: - Tests

    func testFailureEventOnTokenRefreshError() {
        let error = URLError(.unknown)
        var receivedEvents = [RegistrationEvent]()

        // 1. Send events
        wait(
            for: { expectation in
                registration.eventPublisher.sink { event in
                    receivedEvents.append(event)
                    expectation.fulfill()
                }.store(in: &cancellables)
            },
            after: {
                Task(priority: .low) {
                    tokenRefreshTask.subject.send(.tokenReleased)
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
        XCTAssertTrue(registration.receiveEvents())

        // 2. Prepare
        let events: [RegistrationEvent] = [
            .incoming(
                .init(
                    conferenceAlias: "Conference",
                    remoteDisplayName: "Name",
                    token: UUID().uuidString
                )
            ),
            .incomingCancelled(.init(token: UUID().uuidString))
        ]
        var receivedEvents = [RegistrationEvent]()

        // 3. Send events
        wait(
            for: { expectation in
                registration.eventPublisher.sink { event in
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
        XCTAssertTrue(registration.receiveEvents())
        XCTAssertFalse(registration.receiveEvents())
    }

    func testCancel() {
        cancelExpectation = expectation(description: "Cancel expectation")

        // 1. Subscribe to events
        registration.receiveEvents()

        // 2. Cancel
        registration.cancel()

        wait(for: [cancelExpectation!], timeout: 0.1)

        // 3. Assert
        let assertExpectation = expectation(description: "Assert expectation")

        Task {
            XCTAssertFalse(tokenRefreshTask.isCancelCalled)
            XCTAssertTrue(tokenRefreshTask.isCancelAndReleaseCalled)
            XCTAssertTrue(isEventSourceTerminated)
            assertExpectation.fulfill()
        }

        wait(for: [assertExpectation], timeout: 0.1)
    }

    func testDeinit() {
        cancelExpectation = expectation(description: "Cancel expectation")

        // 1. Subscribe to events
        registration.receiveEvents()

        // 2. Cancel
        Task { @MainActor in
            registration = nil
        }

        wait(for: [cancelExpectation!], timeout: 0.1)

        // 3. Assert
        let assertExpectation = expectation(description: "Assert expectation")

        Task {
            XCTAssertTrue(tokenRefreshTask.isCancelCalled)
            XCTAssertTrue(tokenRefreshTask.isCancelAndReleaseCalled)
            XCTAssertTrue(isEventSourceTerminated)
            assertExpectation.fulfill()
        }

        wait(for: [assertExpectation], timeout: 0.1)
    }
}

// MARK: - Mocks

private final class RegistrationDelegateMock: RegistrationDelegate {
    private(set) var events = [RegistrationEvent]()

    func registration(
        _ registration: Registration,
        didReceiveEvent event: RegistrationEvent
    ) {
        events.append(event)
    }
}
