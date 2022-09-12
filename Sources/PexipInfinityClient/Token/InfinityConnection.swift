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
