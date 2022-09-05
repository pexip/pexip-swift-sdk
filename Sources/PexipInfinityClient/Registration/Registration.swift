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
    /// - Returns: False if has already subscribed to the event source,
    ///            True otherwise
    @discardableResult
    func receiveEvents() -> Bool

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
    private let eventSourceTask = Synchronized<EventSourceTask?>(nil)
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
            await tokenRefresher.startRefreshing(onError: { error in
                Task { [weak self] in
                    await self?.handleEvent(.failure(FailureEvent(error: error)))
                }
            })
        }

        logger?.info("Creating a new registration.")
    }

    @discardableResult
    func receiveEvents() -> Bool {
        guard eventSourceTask.value == nil else {
            return false
        }

        eventSourceTask.setValue(Task {
            do {
                for try await event in eventSource.events() {
                    await handleEvent(event)
                }
            } catch {
                eventSourceTask.setValue(nil)
                await handleEvent(.failure(FailureEvent(error: error)))
            }
        })

        return true
    }

    func cancel() async {
        logger?.info("Cancelling all registration activities")
        eventSourceTask.value?.cancel()
        eventSourceTask.setValue(nil)
        await tokenRefresher.endRefreshing(withTokenRelease: true)
    }

    // MARK: - Events

    @MainActor
    private func handleEvent(_ event: RegistrationEvent) {
        delegate?.registration(self, didReceiveEvent: event)
        eventSubject.send(event)
    }
}
