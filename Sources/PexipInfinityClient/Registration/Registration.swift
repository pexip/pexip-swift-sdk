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

import Foundation
import Combine
import PexipCore

// MARK: - Protocol

/// Registration is responsible for subscribing to
/// and handling of the registration events.
public protocol Registration: AnyObject {
    /// The object that acts as the delegate of the registration.
    var delegate: RegistrationDelegate? { get set }

    /// The publisher that publishes registration events
    var eventPublisher: AnyPublisher<RegistrationEvent, Never> { get }

    /// Receives registration events as they occur
    /// - Returns: False if has already subscribed to the event source,
    ///            True otherwise
    @discardableResult
    func receiveEvents() -> Bool

    /// Cancels all registration activities. Once cancelled, the ``Registration`` object is no longer valid.
    func cancel()
}

// MARK: - Implementation

final class DefaultRegistration: Registration {
    weak var delegate: RegistrationDelegate?
    var eventPublisher: AnyPublisher<RegistrationEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    private let connection: InfinityConnection<RegistrationEvent>
    private let logger: Logger?
    private var eventSubject = PassthroughSubject<RegistrationEvent, Never>()
    private var eventTask: Task<Void, Never>?

    // MARK: - Init

    init(
        connection: InfinityConnection<RegistrationEvent>,
        logger: Logger?
    ) {
        self.connection = connection
        self.logger = logger

        eventTask = Task { [weak self] in
            guard let events = self?.connection.events() else {
                return
            }

            for await event in events {
                do {
                    await self?.handleEvent(try event.get())
                } catch {
                    await self?.handleEvent(
                        .failure(FailureEvent(error: error))
                    )
                }
            }
        }

        logger?.info("Creating a new registration.")
    }

    deinit {
        cancelTasks()
    }

    @discardableResult
    func receiveEvents() -> Bool {
        connection.receiveEvents()
    }

    func cancel() {
        logger?.info("Cancelling all registration activities")
        cancelTasks()
    }

    // MARK: - Private

    private func cancelTasks() {
        eventTask?.cancel()
        eventTask = nil
        connection.cancel(withTokenRelease: true)
    }

    @MainActor
    private func handleEvent(_ event: RegistrationEvent) async {
        delegate?.registration(self, didReceiveEvent: event)
        eventSubject.send(event)
    }
}
