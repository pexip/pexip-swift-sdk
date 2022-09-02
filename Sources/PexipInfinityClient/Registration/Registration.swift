import Foundation
import Combine
import PexipCore

// MARK: - Protocol

/// Registration is responsible for subscribing to
/// and handling of the registration events.
public protocol Registration {
    /// The object that acts as the delegate of the registration.
    var delegate: RegistrationDelegate? { get set }

    /// The publisher that publishes registration events
    var eventPublisher: AnyPublisher<RegistrationEvent, Never> { get }

    /// Receives registration events as they occur
    func receiveEvents() async

    /// Cancels all registration activities. Once cancelled, the ``Registration`` object is no longer valid.
    func cancel() async
}

// MARK: - Implementation

final class DefaultRegistration: Registration {
    weak var delegate: RegistrationDelegate?
    var eventPublisher: AnyPublisher<RegistrationEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    private typealias EventSourceTask = Task<Void, Never>

    private let tokenRefresher: TokenRefresher
    private let eventSource: InfinityEventSource<RegistrationEvent>
    private let logger: Logger?
    private let eventSourceTask = Isolated<EventSourceTask?>(nil)
    private var eventSubject = PassthroughSubject<RegistrationEvent, Never>()

    // MARK: - Init

    init(
        tokenRefresher: TokenRefresher,
        eventSource: InfinityEventSource<RegistrationEvent>,
        logger: Logger?
    ) {
        self.tokenRefresher = tokenRefresher
        self.eventSource = eventSource
        self.logger = logger

        Task {
            await tokenRefresher.startRefreshing(onError: { [weak self] in
                self?.handleEvent(.failure(FailureEvent(error: $0)))
            })
        }

        logger?.info("Creating a new registration.")
    }

    func receiveEvents() async {
        guard await eventSourceTask.value == nil else {
            return
        }

        await eventSourceTask.setValue(Task {
            do {
                for try await event in eventSource.events() {
                    handleEvent(event)
                }
            } catch {
                handleEvent(.failure(FailureEvent(error: error)))
                await eventSourceTask.setValue(nil)
            }
        })
    }

    func cancel() async {
        logger?.info("Cancelling all registration activities")
        await eventSourceTask.value?.cancel()
        await eventSourceTask.setValue(nil)
        await tokenRefresher.endRefreshing(withTokenRelease: true)
    }

    // MARK: - Events

    private func handleEvent(_ event: RegistrationEvent) {
        Task { @MainActor in
            delegate?.registration(self, didReceiveEvent: event)
            eventSubject.send(event)
        }
    }
}
