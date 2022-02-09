import Foundation

// MARK: - Protocols

protocol AuthTokenProvider: AnyObject {
    func authToken() async throws -> AuthToken?
}

protocol AuthStorageProtocol: AuthTokenProvider {
    func connectionDetails() async -> ConnectionDetails?
    func storeToken(withTask task: Task<AuthToken, Error>) async throws
    func storeConnectionDetails(_ details: ConnectionDetails) async
    func clear() async
}

extension AuthStorageProtocol {
    func storeToken(_ token: AuthToken) async throws {
        try await storeToken(withTask: Task { token })
    }
}

// MARK: - Implementation

actor AuthStorage: AuthStorageProtocol {
    private var authToken: AuthToken?
    private var authTokenTask: Task<AuthToken, Error>?
    private var connectionDetails: ConnectionDetails?
    private let currentDate: () -> Date

    // MARK: - Init

    init(currentDateProvider: @escaping () -> Date = { Date() }) {
        self.currentDate = currentDateProvider
    }

    deinit {
        cancelAuthTokenTask()
    }

    // MARK: - Auth token

    func authToken() async throws -> AuthToken? {
        if let authTokenTask = authTokenTask {
            let authToken = try await authTokenTask.value
            self.authTokenTask = nil
            return authToken
        } else {
            return authToken
        }
    }

    func storeToken(withTask task: Task<AuthToken, Error>) async throws {
        authTokenTask = task
    }

    // MARK: - Connection details

    func connectionDetails() async -> ConnectionDetails? {
        connectionDetails
    }

    func storeConnectionDetails(_ details: ConnectionDetails) async {
        connectionDetails = details
    }

    // MARK: - Clean up

    func clear() async {
        cancelAuthTokenTask()
        authToken = nil
        connectionDetails = nil
    }

    private func cancelAuthTokenTask() {
        authTokenTask?.cancel()
        authTokenTask = nil
    }
}
