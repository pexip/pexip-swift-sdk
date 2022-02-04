import Foundation

actor AuthSession {
    private let client: AuthClientProtocol
    private let storage: AuthStorageProtocol
    private var tokenRefreshTask: Task<Void, Error>?
    private let currentDate: () -> Date

    var isRefreshScheduled: Bool {
        tokenRefreshTask?.isCancelled == false
    }

    // MARK: - Init

    init(
        client: AuthClientProtocol,
        storage: AuthStorageProtocol,
        currentDateProvider: @escaping () -> Date = { Date() }
    ) {
        self.client = client
        self.storage = storage
        self.currentDate = currentDateProvider
    }

    deinit {
        stopRefreshTask()
    }

    // MARK: - Session management

    func activate(
        displayName: String,
        pin: String? = nil,
        conferenceExtension: String? = nil
    ) async throws {
        // Release current token if present
        try await deactivate()

        let (token, connectionDetails) = try await client.requestToken(
            displayName: displayName,
            pin: pin,
            conferenceExtension: conferenceExtension
        )

        try await storage.storeToken(token)
        await storage.storeConnectionDetails(connectionDetails)
        scheduleRefresh(for: token)
    }

    func deactivate() async throws {
        stopRefreshTask()

        let token = try await storage.authToken()
        await storage.clear()

        if token?.isExpired(currentDate: currentDate()) == false {
            try await client.releaseToken()
        }
    }

    // MARK: - Token refresh flow

    private func scheduleRefresh(for authToken: AuthToken) {
        stopRefreshTask()

        guard !authToken.isExpired(currentDate: currentDate()) else {
            return
        }

        tokenRefreshTask = Task<Void, Error> {
            do {
                let timeInterval = authToken.refreshDate.timeIntervalSince(currentDate())

                try await Task.sleep(seconds: timeInterval)
                try await storage.storeToken(withTask: Task {
                    let newAuthToken = try await client.refreshToken()
                    scheduleRefresh(for: newAuthToken)
                    return newAuthToken
                })
            } catch {
                stopRefreshTask()
                throw error
            }
        }
    }

    private func stopRefreshTask() {
        tokenRefreshTask?.cancel()
        tokenRefreshTask = nil
    }
}
