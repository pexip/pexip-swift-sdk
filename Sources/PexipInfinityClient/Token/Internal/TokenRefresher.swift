import Foundation
import PexipCore

// MARK: - Protocol

protocol TokenRefresher {
    var isRefreshing: Bool { get async }

    @discardableResult
    func startRefreshing(onError: ((Error) -> Void)?) async -> Bool

    @discardableResult
    func endRefreshing(withTokenRelease: Bool) async -> Bool
}

// MARK: - Implementaion

actor DefaultTokenRefresher<Token: InfinityToken>: TokenRefresher {
    private let service: TokenService
    private let store: TokenStore<Token>
    private let logger: Logger?
    private let currentDate: () -> Date
    private var tokenRefreshTask: Task<Void, Error>?

    var isRefreshing: Bool {
        return tokenRefreshTask != nil
    }

    // MARK: - Init

    init(
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
    func startRefreshing(onError: ((Error) -> Void)? = nil) async -> Bool {
        do {
            guard !isRefreshing else {
                throw TokenRefresherError.tokenRefreshStarted
            }

            let token = try await store.token()
            try await scheduleRefresh(for: token, onError: onError)
            logger?.info("\(String(reflecting: token)) refresh operation started ✅")
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

    private func scheduleRefresh(
        for token: Token,
        onError: ((Error) -> Void)? = nil
    ) async throws {
        await stopRefreshTask()

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
                onError?(error)
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
