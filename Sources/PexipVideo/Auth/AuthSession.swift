import Foundation

actor AuthSession {
    private let client: AuthClientProtocol
    private let storage: AuthStorageProtocol
    private let logger: CategoryLogger
    private var tokenRefreshTask: Task<Void, Error>?
    private let currentDate: () -> Date

    var isRefreshScheduled: Bool {
        tokenRefreshTask?.isCancelled == false
    }

    // MARK: - Init

    init(
        client: AuthClientProtocol,
        storage: AuthStorageProtocol,
        logger: CategoryLogger,
        currentDateProvider: @escaping () -> Date = { Date() }
    ) {
        self.client = client
        self.storage = storage
        self.logger = logger
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
        if try await storage.authToken() != nil {
            try await deactivate()
        }

        logger.debug("Requesting a new token from the Pexip Conferencing Node...")

        let (token, connectionDetails) = try await client.requestToken(
            displayName: displayName,
            pin: pin,
            conferenceExtension: conferenceExtension
        )

        try await storage.storeToken(token)
        await storage.storeConnectionDetails(connectionDetails)

        scheduleRefresh(for: token)
        logger.info("Auth session activated ✅")
    }

    func deactivate() async throws {
        stopRefreshTask()

        let token = try await storage.authToken()
        await storage.clear()

        if let token = token, !token.isExpired(currentDate: currentDate()) {
            logger.debug("Releasing the token...")
            try await client.releaseToken(token)
        }

        logger.info("Auth session deactivated ⛔️")
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

                logger.debug("Scheduling token refresh in \(timeInterval)")

                try await Task.sleep(seconds: timeInterval)

                try await storage.storeToken(withTask: Task {
                    logger.debug("Refreshing a token to get a new one...")
                    let newAuthToken = try await client.refreshToken(authToken)
                    logger.debug("New token received 👌")

                    scheduleRefresh(for: newAuthToken)
                    return newAuthToken
                })
            } catch {
                stopRefreshTask()
                logger.error("Token refresh failed with error: \(error)")
                throw error
            }
        }
    }

    private func stopRefreshTask() {
        tokenRefreshTask?.cancel()
        tokenRefreshTask = nil
    }
}
