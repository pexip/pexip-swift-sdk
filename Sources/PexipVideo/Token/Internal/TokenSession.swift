import Foundation

// MARK: - Protocol

protocol TokenSessionProtocol {
    @discardableResult
    func activate() async -> Bool

    @discardableResult
    func deactivate(releaseToken: Bool) async -> Bool

    var isActive: Bool { get async }
}

// MARK: - Implementaion

actor TokenSession: TokenSessionProtocol {
    private let client: TokenManagerClientProtocol
    private let storage: TokenStorageProtocol
    private let logger: CategoryLogger
    private var tokenRefreshTask: Task<Void, Error>?
    private let currentDate: () -> Date

    var isActive: Bool {
        get async {
            return tokenRefreshTask != nil
        }
    }

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

    @discardableResult
    func activate() async -> Bool {
        do {
            guard let token = try await storage.token() else {
                throw TokenSessionError.noToken
            }

            guard await !isActive else {
                throw TokenSessionError.sessionAlreadyActive
            }

            logger.info("Token session activated ✅")
            scheduleRefresh(for: token)
            return true
        } catch {
            logger.warn("Wrong use of TokenSession.activate: \(error)")
            return false
        }
    }

    @discardableResult
    func deactivate(releaseToken: Bool) async -> Bool {
        do {
            guard await isActive else {
                throw TokenSessionError.sessionAlreadyInactive
            }

            stopRefreshTask()

            let token = try await storage.token()
            await storage.clear()

            if releaseToken {
                if let token = token, !token.isExpired(currentDate: currentDate()) {
                    logger.debug("Releasing the token...")
                    do {
                        try await client.releaseToken(token)
                    } catch {
                        logger.error("Release token request failed: \(error)")
                    }
                }
            }

            logger.info("Token session deactivated ⛔️")
            return true
        } catch {
            logger.warn("Wrong use of TokenSession.deactivate: \(error)")
            return false
        }
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

private enum TokenSessionError: LocalizedError, CustomStringConvertible {
    case noToken
    case sessionAlreadyActive
    case sessionAlreadyInactive

    var description: String {
        switch self {
        case .noToken:
            return "No token"
        case .sessionAlreadyActive:
            return "Session is already active"
        case .sessionAlreadyInactive:
            return "Session is already inactive"
        }
    }
}
