import Foundation
import PexipInfinityClient
import KeychainAccess

final class RegistrationService {
    var deviceAlias: String? { userDefaults[string: .deviceAlias] }
    var username: String? { keychain[string: .username] }
    var password: String? { keychain[string: .password] }
    var onCallReceived: ((IncomingRegistrationEvent) -> Void)?
    var onCallCancelled: ((IncomingCancelledRegistrationEvent) -> Void)?

    var isRegistered: Bool {
        registration != nil
    }

    private let factory: InfinityClientFactory
    private let userDefaults: UserDefaults
    private let keychain: Keychain
    private var registration: Registration?

    // MARK: - Init

    init(
        factory: InfinityClientFactory,
        userDefaults: UserDefaults = .standard,
        keychain: Keychain = .init()
    ) {
        self.factory = factory
        self.userDefaults = userDefaults
        self.keychain = keychain
    }

    // MARK: - Registration

    func register(
        deviceAlias: String,
        username: String,
        password: String
    ) async throws {
        guard let deviceAlias = DeviceAlias(uri: deviceAlias) else {
            throw RegistrationError.invalidDeviceAlias
        }

        await unregister()

        let service = factory.infinityService()
        let nodeResolver = InfinityClientFactory().nodeResolver(dnssec: false)

        guard let nodeURL = try await service.resolveNodeURL(
            forHost: deviceAlias.host,
            using: nodeResolver
        ) else {
            throw RegistrationError.invalidDeviceAlias
        }

        let token = try await service.node(url: nodeURL)
            .registration(deviceAlias: deviceAlias)
            .requestToken(username: username, password: password)

        registration = factory.registration(
            node: nodeURL,
            deviceAlias: deviceAlias,
            token: token
        )
        registration?.delegate = self
        registration?.receiveEvents()

        userDefaults[string: .deviceAlias] = deviceAlias.uri
        keychain[string: .username] = username
        keychain[string: .password] = password
    }

    func registerFromStorage() async throws {
        guard
            let deviceAlias = deviceAlias,
            let username = username,
            let password = password
        else {
            throw RegistrationError.noRegistrationDataFound
        }

        try await register(
            deviceAlias: deviceAlias,
            username: username,
            password: password
        )
    }

    func unregister() async {
        registration?.cancel()
        registration = nil
        userDefaults[string: .deviceAlias] = nil
        keychain[string: .username] = nil
        keychain[string: .password] = nil
    }
}

// MARK: - RegistrationDelegate

extension RegistrationService: RegistrationDelegate {
    func registration(
        _ registration: Registration,
        didReceiveEvent event: RegistrationEvent
    ) {
        switch event {
        case .incoming(let event):
            onCallReceived?(event)
        case .incomingCancelled(let event):
            onCallCancelled?(event)
        case .failure(let event):
            debugPrint(event.error)
        }
    }
}

// MARK: - Errors

enum RegistrationError: LocalizedError {
    case invalidDeviceAlias
    case noRegistrationDataFound

    var errorDescription: String? {
        switch self {
        case .invalidDeviceAlias:
            return "Invalid device alias."
        case .noRegistrationDataFound:
            return "No registration data found"
        }
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
