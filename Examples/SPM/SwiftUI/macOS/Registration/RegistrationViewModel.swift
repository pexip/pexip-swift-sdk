import SwiftUI
import PexipInfinityClient

final class RegistrationViewModel: ObservableObject {
    @Published var alias = ""
    @Published var username: String
    @Published var password: String
    @Published var isRegistered = false
    @Published private(set) var errorMessage: String?

    private let service: RegistrationService

    var isValid: Bool {
        DeviceAlias(uri: alias) != nil && !username.isEmpty && !password.isEmpty
    }

    // MARK: - Init

    init(service: RegistrationService) {
        self.service = service
        self.alias = service.deviceAlias ?? ""
        self.username = service.username ?? ""
        self.password = service.password ?? ""
        self.isRegistered = service.isRegistered
    }

    // MARK: - Actions

    @MainActor
    func register() async {
        guard isValid else {
            errorMessage = "Required fields are missing"
            return
        }

        do {
            try await service.register(
                deviceAlias: alias,
                username: username,
                password: password
            )
            isRegistered = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func unregister() async {
        await service.unregister()
        isRegistered = false
    }
}
