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

        guard let node = await resolveNode() else {
            errorMessage = "Looks like the address you typed in doesn't exist"
            return
        }

        do {
            let token = try await service
                .node(url: node)
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

    private func resolveNode() async -> URL? {
        guard let deviceAlias = deviceAlias else {
            return nil
        }

        do {
            for url in try await nodeResolver.resolveNodes(for: deviceAlias.host) {
                if try await service.node(url: url).status() {
                    return url
                }
            }
        } catch {
            return nil
        }

        return nil
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
