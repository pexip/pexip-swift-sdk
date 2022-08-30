import Foundation
import PexipUtils

// MARK: - Protocol

public protocol TokenRefresher {
    var isRefreshing: Bool { get async }

    @discardableResult
    func startRefreshing() async -> Bool

    @discardableResult
    func endRefreshing(withTokenRelease: Bool) async -> Bool
}

// MARK: - Implementaion

public actor DefaultTokenRefresher<Token: InfinityToken>: TokenRefresher {
    private let service: TokenService
    private let store: TokenStore<Token>
    private let logger: Logger?
    private var tokenRefreshTask: Task<Void, Error>?
    private let currentDate: () -> Date

    public var isRefreshing: Bool {
        return tokenRefreshTask != nil
    }

    // MARK: - Init

    public init(
        service: TokenService,
        store: TokenStore<Token>,
        logger: Logger? = nil,
        currentDateProvider: @escaping () -> Date = { Date() }
    ) {
        self.service = service
        self.store = store
        self.logger = logger
        self.currentDate = currentDateProvider
    }

    // MARK: - TokenRefresher

    @discardableResult
    public func startRefreshing() async -> Bool {
        do {
            guard !isRefreshing else {
                throw TokenRefresherError.tokenRefreshStarted
            }

            let token = try await store.token()
            try await scheduleRefresh(for: token)
            logger?.info("\(String(reflecting: token)) refresh operation started ✅")
            return true
        } catch {
            logger?.warn("Wrong use of TokenRefresher.startRefreshing: \(error)")
            return false
        }
    }

    @discardableResult
    public func endRefreshing(withTokenRelease: Bool) async -> Bool {
        do {
            guard isRefreshing else {
                throw TokenRefresherError.tokenRefreshEnded
            }

            await stopRefreshTask()

            let token = try await store.token()

            if withTokenRelease {
                if !token.isExpired(currentDate: currentDate()) {
                    logger?.debug("Releasing the \(String(reflecting: token))...")
                    do {
                        try await service.releaseToken(token)
                    } catch {
                        logger?.error("Release \(String(reflecting: token)) request failed: \(error)")
                    }
                }
            }

            logger?.info("\(String(reflecting: token)) refresh operation ended ⛔️")
            return true
        } catch {
            switch error as? InfinityTokenError {
            case .tokenExpired:
                logger?.info("Token refresh operation ended ⛔️")
                return true
            case .none:
                logger?.warn("Wrong use of TokenRefresher.endRefreshing: \(error)")
                return false
            }
        }
    }

    // MARK: - Token refresh flow

    private func scheduleRefresh(for token: Token) async throws {
        await stopRefreshTask()

        guard !token.isExpired(currentDate: currentDate()) else {
            logger?.warn("Cannot schedule refresh for expired \(String(reflecting: token))")
            throw TokenRefresherError.tokenExpired
        }

        tokenRefreshTask = Task<Void, Error> {
            do {
                let timeInterval = token.refreshDate.timeIntervalSince(currentDate())

                logger?.debug("Scheduling \(String(reflecting: token)) refresh in \(timeInterval)")

                try await Task.sleep(seconds: timeInterval)

                try await store.updateToken(withTask: Task {
                    logger?.debug("Refreshing a \(String(reflecting: token)) to get a new one...")
                    let refreshTokenResponse = try await service.refreshToken(token)
                    let newToken = token.updating(
                        value: refreshTokenResponse.token,
                        expires: refreshTokenResponse.expires,
                        updatedAt: currentDate()
                    )
                    logger?.debug("New \(String(reflecting: token)) received 👌")
                    try await scheduleRefresh(for: newToken)
                    return newToken
                })
            } catch {
                await stopRefreshTask()
                logger?.error("\(String(reflecting: token)) refresh failed with error: \(error)")
                throw error
            }
        }
    }

    private func stopRefreshTask() async {
        tokenRefreshTask?.cancel()
        tokenRefreshTask = nil
        await store.cancelUpdateIfNeeded()
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
