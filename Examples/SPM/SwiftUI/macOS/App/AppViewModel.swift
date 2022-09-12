import Foundation
import AppKit
import PexipInfinityClient

final class AppViewModel: ObservableObject {
    @Published var incomingCallEvent: IncomingRegistrationEvent?

    let infinityClientFactory: InfinityClientFactory
    let registrationService: RegistrationService
    let viewFactory: ViewFactory

    init() {
        infinityClientFactory = InfinityClientFactory()
        viewFactory = ViewFactory(
            apiClientFactory: infinityClientFactory,
            settings: Settings()
        )
        registrationService = RegistrationService(
            factory: infinityClientFactory
        )
        registrationService.onCallReceived = { [weak self] event in
            self?.incomingCallEvent = event
            self?.openWindow(.incomingCall)
        }
        registrationService.onCallCancelled = { [weak self] _ in
            self?.incomingCallEvent = nil
        }

        Task {
            do {
                try await registrationService.registerFromStorage()
            } catch {
                debugPrint("Registration service: \(error)")
            }
        }
    }

    func openWindow(_ window: AppWindow) {
        if let url = URL(string: "pexipdemo://\(window.rawValue)") {
            NSWorkspace.shared.open(url)
        }
    }
}
