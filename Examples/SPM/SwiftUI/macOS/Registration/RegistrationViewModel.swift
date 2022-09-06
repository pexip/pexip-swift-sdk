import PexipMedia
import Combine
import SwiftUI
import PexipInfinityClient
import KeychainAccess

final class RegistrationViewModel: ObservableObject {
    typealias Complete = (RegistrationToken) -> Void

    @AppStorage("deviceAlias") var alias = ""
    @Published var username: String
    @Published var password: String
    @Published private(set) var errorMessage: String?

    private let keychain = Keychain()
    private let nodeResolver: NodeResolver
    private let service: InfinityService
    private let onComplete: Complete
    private let onCancel: () -> Void
    private var cancellables = Set<AnyCancellable>()
    private var deviceAlias: DeviceAlias? {
        DeviceAlias(uri: alias)
    }

    var isValid: Bool {
        deviceAlias != nil && !username.isEmpty && !password.isEmpty
    }

    // MARK: - Init

    init(
        nodeResolver: NodeResolver,
        service: InfinityService,
        onComplete: @escaping Complete,
        onCancel: @escaping () -> Void
    ) {
        self.nodeResolver = nodeResolver
        self.service = service
        self.onComplete = onComplete
        self.onCancel = onCancel
        self.username = keychain[string: .username] ?? ""
        self.password = keychain[string: .password] ?? ""

        $username.sink { [weak self] newValue in
            self?.keychain[string: .username] = newValue
        }.store(in: &cancellables)

        $password.sink { [weak self] newValue in
            self?.keychain[string: .password] = newValue
        }.store(in: &cancellables)
    }

    // MARK: - Actions

    @MainActor
    func register() async {
        guard let deviceAlias = deviceAlias, isValid else {
            errorMessage = "Required fields are missing"
            return
        }

        guard let node = try? await service.resolveNode(
            forHost: deviceAlias.host,
            using: nodeResolver
        ) else {
            errorMessage = "Looks like the address you typed in doesn't exist"
            return
        }

        do {
            let token = try await node
                .registration(deviceAlias: deviceAlias)
                .requestToken(username: username, password: password)
            onComplete(token)
        } catch {
            debugPrint(error)
            errorMessage = "Registration failed. Please double-check your credentials."
        }
    }

    func cancel() {
        onCancel()
    }
}

// MARK: - Private extensions

private extension Keychain {
    enum Key: String {
        case username
        case password
    }

    subscript(string key: Key) -> String? {
        get { self[key.rawValue] }
        set { self[key.rawValue] = newValue }
    }
}
