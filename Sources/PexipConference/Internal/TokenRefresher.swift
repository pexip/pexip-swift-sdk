import Foundation
import PexipInfinityClient
import PexipUtils

// MARK: - Protocol

protocol TokenRefresher {
    var isRefreshing: Bool { get async }

    @discardableResult
    func startRefreshing() async -> Bool

    @discardableResult
    func endRefreshing(withTokenRelease: Bool) async -> Bool
}

// MARK: - Implementaion

actor DefaultTokenRefresher: TokenRefresher {
    private let service: TokenService
    private let store: TokenStore
    private let logger: Logger?
    private var tokenRefreshTask: Task<Void, Error>?
    private let currentDate: () -> Date

    var isRefreshing: Bool {
        return tokenRefreshTask != nil
    }

    // MARK: - Init

    init(
        service: TokenService,
        store: TokenStore,
        logger: Logger? = nil,
        currentDateProvider: @escaping () -> Date = { Date() }
    ) {
        self.service = service
        self.store = store
        self.logger = logger
        self.currentDate = currentDateProvider
    }

    deinit {
        stopRefreshTask()
    }

    // MARK: - TokenRefresher

    @discardableResult
    func startRefreshing() async -> Bool {
        do {
            guard !isRefreshing else {
                throw TokenRefresherError.tokenRefreshStarted
            }

            let token = try await store.token()
            try scheduleRefresh(for: token)
            logger?.info("Token refresh operation started ✅")
            return true
        } catch {
            logger?.warn("Wrong use of TokenRefresher.startRefreshing: \(error)")
            return false
        }
    }

    @discardableResult
    func endRefreshing(withTokenRelease: Bool) async -> Bool {
        do {
            guard isRefreshing else {
                throw TokenRefresherError.tokenRefreshEnded
            }

            stopRefreshTask()

            let token = try await store.token()

            if withTokenRelease {
                if !token.isExpired(currentDate: currentDate()) {
                    logger?.debug("Releasing the token...")
                    do {
                        try await service.releaseToken(token)
                    } catch {
                        logger?.error("Release token request failed: \(error)")
                    }
                }
            }

            logger?.info("Token refresh operation ended ⛔️")
            return true
        } catch {
            logger?.warn("Wrong use of TokenRefresher.endRefreshing: \(error)")
            return false
        }
    }

    // MARK: - Token refresh flow

    private func scheduleRefresh(for token: Token) throws {
        stopRefreshTask()

        guard !token.isExpired(currentDate: currentDate()) else {
            logger?.warn("Cannot schedule refresh for expired token")
            throw TokenRefresherError.tokenExpired
        }

        tokenRefreshTask = Task<Void, Error> {
            do {
                let timeInterval = token.refreshDate.timeIntervalSince(currentDate())

                logger?.debug("Scheduling token refresh in \(timeInterval)")

                try await Task.sleep(seconds: timeInterval)

                try await store.updateToken(withTask: Task {
                    logger?.debug("Refreshing a token to get a new one...")
                    let newToken = try await service.refreshToken(token)
                    logger?.debug("New token received 👌")
                    try scheduleRefresh(for: newToken)
                    return newToken
                })
            } catch {
                stopRefreshTask()
                logger?.error("Token refresh failed with error: \(error)")
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

private enum TokenRefresherError: LocalizedError, CustomStringConvertible {
    case tokenRefreshStarted
    case tokenRefreshEnded
    case tokenExpired

    var description: String {
        switch self {
        case .tokenRefreshStarted:
            return "Token refresh has already started"
        case .tokenRefreshEnded:
            return "Token refresh has already ended"
        case .tokenExpired:
            return "Cannot schedule refresh for expired token"
        }
    }
}
