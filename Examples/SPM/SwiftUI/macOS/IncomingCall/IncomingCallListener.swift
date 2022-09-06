import Foundation
import PexipInfinityClient

final class IncomingCallListener {
    private let registration: Registration

    init(registration: Registration) {
        self.registration = registration
        registration.delegate = self
    }

    func start() {
        registration.receiveEvents()
    }

    func stop() {
        Task {
            await registration.cancel()
        }
    }
}

// MARK: - RegistrationDelegate

extension IncomingCallListener: RegistrationDelegate {
    func registration(
        _ registration: Registration,
        didReceiveEvent event: RegistrationEvent
    ) {
        switch event {
        case .incoming(let event):
            break
        case .incomingCancelled(let event):
            break
        case .failure(let event):
            debugPrint(event.error)
        }
    }
}
