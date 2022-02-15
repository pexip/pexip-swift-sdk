import Foundation

// MARK: - Protocol

protocol TokenSessionProtocol {
    func activate() async throws
    func deactivate() async throws
}

// MARK: - Implementaion

actor TokenSession: TokenSessionProtocol {
    private let client: TokenManagerClientProtocol
    private let storage: TokenStorageProtocol
    private let logger: CategoryLogger
    private var tokenRefreshTask: Task<Void, Error>?
    private let currentDate: () -> Date
    private var isDeactivated = false

    var isRefreshScheduled: Bool {
        tokenRefreshTask?.isCancelled == false
    }

    // MARK: - Init

    init(
        client: TokenManagerClientProtocol,
        storage: TokenStorageProtocol,
        logger: LoggerProtocol,
        currentDateProvider: @escaping () -> Date = { Date() }
    ) {
        self.client = client
        self.storage = storage
        self.logger = logger[.auth]
        self.currentDate = currentDateProvider
    }

    deinit {
        stopRefreshTask()
    }

    // MARK: - Session management

    func activate() async throws {
        guard let token = try await storage.token(), !isDeactivated else {
            throw TokenSessionError.cannotActivateDeactivatedSession
        }

        guard tokenRefreshTask == nil else {
            throw TokenSessionError.sessionAlreadyActive
        }

        logger.info("Token session activated ✅")
        scheduleRefresh(for: token)
    }

    func deactivate() async throws {
        guard !isDeactivated else {
            throw TokenSessionError.cannotDeactivateDeactivatedSession
        }

        stopRefreshTask()

        let token = try await storage.token()
        await storage.clear()

        if let token = token, !token.isExpired(currentDate: currentDate()) {
            logger.debug("Releasing the token...")
            try await client.releaseToken(token)
        }

        isDeactivated = true
        logger.info("Token session deactivated ⛔️")
    }

    // MARK: - Token refresh flow

    private func scheduleRefresh(for token: Token) {
        stopRefreshTask()

        guard !token.isExpired(currentDate: currentDate()) else {
            logger.warn("Cannot schedule refresh for expired token")
            return
        }

        tokenRefreshTask = Task<Void, Error> {
            do {
                let timeInterval = token.refreshDate.timeIntervalSince(currentDate())

                logger.debug("Scheduling token refresh in \(timeInterval)")

                try await Task.sleep(seconds: timeInterval)

                try await storage.updateToken(withTask: Task {
                    logger.debug("Refreshing a token to get a new one...")
                    let newToken = try await client.refreshToken(token)
                    logger.debug("New token received 👌")
                    scheduleRefresh(for: newToken)
                    return newToken
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

// MARK: - Errors

enum TokenSessionError: LocalizedError {
    case sessionAlreadyActive
    case cannotActivateDeactivatedSession
    case cannotDeactivateDeactivatedSession

    var errorDescription: String? {
        switch self {
        case .sessionAlreadyActive:
            return "Session is already active"
        case .cannotActivateDeactivatedSession:
            return "Cannot activate deactivated token session"
        case .cannotDeactivateDeactivatedSession:
            return "Cannot deactivate already deactivated token session"
        }
    }
}
