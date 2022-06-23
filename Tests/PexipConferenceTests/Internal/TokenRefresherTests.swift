import XCTest
@testable import PexipConference
@testable import PexipInfinityClient

final class TokenRefresherTests: XCTestCase {
    private var refresher: TokenRefresher!
    private var store: TokenStoreMock!
    private var service: TokenServiceMock!
    private var calendar: Calendar!
    private var updatedAt: Date!
    private var currentDate = Date()

    // MARK: - Setup

    // swiftlint:disable unowned_variable_capture
    override func setUpWithError() throws {
        try super.setUpWithError()

        calendar = Calendar.current
        calendar.timeZone = try XCTUnwrap(TimeZone(abbreviation: "GMT"))
        updatedAt = try XCTUnwrap(
            DateComponents(
                calendar: calendar,
                year: 2022,
                month: 1,
                day: 27,
                hour: 13,
                minute: 16,
                second: 11
            ).date
        )
        store = TokenStoreMock()
        service = TokenServiceMock()
        refresher = DefaultTokenRefresher(
            service: service,
            store: store,
            currentDateProvider: { [unowned self] in
                self.currentDate
            }
        )
    }

    // MARK: - Start refreshing tests

    func testStartRefreshing() async throws {
        let token = Token.randomToken(updatedAt: updatedAt)
        currentDate = updatedAt.addingTimeInterval(60)

        try await store.updateToken(token)
        let started = await refresher.startRefreshing()
        let isRefreshing = await refresher.isRefreshing
        let tokenFromStore = try await store.token()

        XCTAssertEqual(tokenFromStore, token)
        XCTAssertTrue(started)
        XCTAssertTrue(isRefreshing)
    }

    func testStartRefreshingWhenRefreshing() async throws {
        try await store.updateToken(Token.randomToken())
        await refresher.startRefreshing()
        let started = await refresher.startRefreshing()

        XCTAssertFalse(started)
    }

    // MARK: - Token refresh tests

    /// N.B. Testing timers is tricky
    func testTokenRefresh() async throws {
        let tokenA = Token.randomToken(updatedAt: updatedAt)
        let tokenB = Token.randomToken(updatedAt: updatedAt)

        currentDate = updatedAt.addingTimeInterval(59.8)
        service.refreshTokenResult = .success(tokenB)

        // 1. Start refreshing to schedule token refresh
        try await store.updateToken(tokenA)
        await refresher.startRefreshing()

        let tokenFromStore = try await store.token()
        let isRefreshing = await refresher.isRefreshing

        XCTAssertEqual(tokenFromStore, tokenA)
        XCTAssertTrue(isRefreshing)

        // 2. Wait for token refresh
        let waitForRefresh = Task {
            try await Task.sleep(seconds: 0.3)

            XCTAssertEqual(service.steps, [.refreshToken])

            let tokenFromStore = try await store.token()
            let isRefreshing = await refresher.isRefreshing

            XCTAssertEqual(tokenFromStore, tokenB)
            XCTAssertTrue(isRefreshing)
        }

        try await waitForRefresh.value
    }

    /// N.B. Testing timers is tricky
    func testTokenRefreshWithServiceError() async throws {
        let tokenA = Token.randomToken(updatedAt: updatedAt)

        currentDate = updatedAt.addingTimeInterval(60)
        service.refreshTokenResult = .failure(URLError(.badURL))

        // 1. Start refreshing to schedule token refresh
        try await store.updateToken(tokenA)
        await refresher.startRefreshing()

        let tokenFromStore = try await store.token()
        let isRefreshing = await refresher.isRefreshing

        XCTAssertEqual(tokenFromStore, tokenA)
        XCTAssertTrue(isRefreshing)

        // 2. Wait to token refresh
        let waitForRefresh = Task {
            try await Task.sleep(seconds: 0.1)

            XCTAssertEqual(service.steps, [.refreshToken])

            let tokenFromStore = try await store.token()
            let isRefreshing = await refresher.isRefreshing

            XCTAssertEqual(tokenFromStore, tokenA)
            XCTAssertFalse(isRefreshing)
        }

        try await waitForRefresh.value
    }

    func testTokenRefreshWithExpiredToken() async throws {
        let tokenA = Token.randomToken(updatedAt: updatedAt.addingTimeInterval(-240))
        let tokenB = Token.randomToken(updatedAt: updatedAt)

        currentDate = updatedAt.addingTimeInterval(60)
        service.refreshTokenResult = .success(tokenB)

        // 1. Activate refresher and schedule token refresh
        try await store.updateToken(tokenA)
        await refresher.startRefreshing()

        let tokenFromStore = try await store.token()
        let isRefreshing = await refresher.isRefreshing

        XCTAssertEqual(tokenFromStore, tokenA)
        XCTAssertFalse(isRefreshing)
    }

    // MARK: - End refreshing tests

    func testEndRefreshingWithValidToken() async throws {
        let token = Token.randomToken(updatedAt: updatedAt)
        service.releaseTokenResult = .success(())
        currentDate = updatedAt.addingTimeInterval(60)

        try await store.updateToken(token)
        await refresher.startRefreshing()
        let ended = await refresher.endRefreshing(withTokenRelease: true)
        let isRefreshing = await refresher.isRefreshing

        XCTAssertTrue(ended)
        XCTAssertFalse(isRefreshing)
        XCTAssertEqual(service.steps, [.releaseToken])
    }

    func testEndRefreshingWithServiceError() async throws {
        let token = Token.randomToken(updatedAt: updatedAt)

        service.releaseTokenResult = .failure(URLError(.badURL))
        currentDate = updatedAt.addingTimeInterval(60)

        try await store.updateToken(token)
        await refresher.startRefreshing()
        let ended = await refresher.endRefreshing(withTokenRelease: true)
        let isRefreshing = await refresher.isRefreshing

        XCTAssertTrue(ended)
        XCTAssertFalse(isRefreshing)
        XCTAssertEqual(service.steps, [.releaseToken])
    }

    func testEndRefreshingWithExpiredToken() async throws {
        let token = Token.randomToken(updatedAt: updatedAt)
        try await store.updateToken(token)
        currentDate = updatedAt.addingTimeInterval(60)
        await refresher.startRefreshing()
        currentDate = updatedAt.addingTimeInterval(120)
        let ended = await refresher.endRefreshing(withTokenRelease: true)
        let isRefreshing = await refresher.isRefreshing

        XCTAssertTrue(ended)
        XCTAssertFalse(isRefreshing)
        XCTAssertTrue(service.steps.isEmpty)
    }

    func testEndRefreshingWhenNotRefreshing() async throws {
        let deactivated = await refresher.endRefreshing(withTokenRelease: true)
        XCTAssertFalse(deactivated)
    }

    func testEndRefreshingWithoutTokenRelease() async throws {
        let token = Token.randomToken(updatedAt: updatedAt)
        service.releaseTokenResult = .success(())
        currentDate = updatedAt.addingTimeInterval(60)

        try await store.updateToken(token)
        await refresher.startRefreshing()
        let ended = await refresher.endRefreshing(withTokenRelease: false)
        let isRefreshing = await refresher.isRefreshing

        XCTAssertTrue(ended)
        XCTAssertFalse(isRefreshing)
        XCTAssertTrue(service.steps.isEmpty)
    }
}

// MARK: - Mocks

private final class TokenServiceMock: TokenService {
    enum Step: Equatable {
        case refreshToken
        case releaseToken
    }

    var refreshTokenResult: Result<Token, Error> = .failure(URLError(.badURL))
    var releaseTokenResult: Result<Void, Error> = .success(())
    private(set) var steps = [Step]()

    func requestToken(
        fields: RequestTokenFields,
        pin: String?
    ) async throws -> Token {
        fatalError("Should not be called")
    }

    func refreshToken(_ token: Token) async throws -> Token {
        steps.append(.refreshToken)
        return try refreshTokenResult.get()
    }

    func releaseToken(_ token: Token) async throws {
        steps.append(.releaseToken)
        try releaseTokenResult.get()
    }
}

private final class TokenStoreMock: TokenStore {
    var token: Token = .randomToken()
    var updateTokenError: Error?

    func token() async throws -> Token {
        return token
    }

    func updateToken(withTask task: Task<Token, Error>) async throws {
        if let updateTokenError = updateTokenError {
            throw updateTokenError
        }
        token = try await task.value
    }
}
