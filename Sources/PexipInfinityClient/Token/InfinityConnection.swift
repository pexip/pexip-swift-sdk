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

import PexipCore
import Combine

final class InfinityConnection<Event> {
    typealias EventResult = Result<Event, Error>

    private typealias EventSourceTask = Task<Void, Never>

    private let tokenRefreshTask: TokenRefreshTask
    private let eventSource: InfinityEventSource<Event>
    private let eventSourceTask = Synchronized<EventSourceTask?>(nil)
    private var cancellables = Set<AnyCancellable>()
    private var subscribers = [AsyncStream<EventResult>.Continuation]()

    // MARK: - Init

    init(
        tokenRefreshTask: TokenRefreshTask,
        eventSource: InfinityEventSource<Event>
    ) {
        self.tokenRefreshTask = tokenRefreshTask
        self.eventSource = eventSource

        tokenRefreshTask.eventPublisher.sink { [weak self] event in
            switch event {
            case .failed(let error):
                self?.send(.failure(error))
            default:
                break
            }
        }.store(in: &cancellables)
    }

    deinit {
        cancel(withTokenRelease: false)
    }

    // MARK: - Internal

    func events() -> AsyncStream<EventResult> {
        AsyncStream { continuation in
            subscribers.append(continuation)
        }
    }

    @discardableResult
    func receiveEvents() -> Bool {
        guard eventSourceTask.value == nil else {
            return false
        }

        eventSourceTask.setValue(Task { [weak self] in
            guard let events = self?.eventSource.events() else {
                return
            }

            do {
                for try await event in events {
                    self?.send(.success(event))
                }
            } catch {
                self?.cancelEventSourceTask()
                self?.send(.failure(error))
            }
        })

        return true
    }

    func cancel(withTokenRelease: Bool) {
        for subscriber in subscribers {
            subscriber.finish()
        }

        subscribers.removeAll()
        cancelEventSourceTask()

        if withTokenRelease {
            tokenRefreshTask.cancelAndRelease()
        } else {
            tokenRefreshTask.cancel()
        }
    }

    // MARK: - Private

    private func send(_ event: EventResult) {
        for subscriber in subscribers {
            subscriber.yield(event)
        }
    }

    private func cancelEventSourceTask() {
        eventSourceTask.value?.cancel()
        eventSourceTask.setValue(nil)
    }
}
