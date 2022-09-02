import XCTest
@testable import PexipInfinityClient

final class TokenRefresherTests: XCTestCase {
    private var refresher: DefaultTokenRefresher<ConferenceToken>!
    private var store: TokenStore<ConferenceToken>!
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
        store = TokenStore(
            token: .randomToken(),
            currentDateProvider: { [unowned self] in
                self.currentDate
            }
        )
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
        let token = ConferenceToken.randomToken(updatedAt: updatedAt)
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
        try await store.updateToken(ConferenceToken.randomToken())
        await refresher.startRefreshing()
        let started = await refresher.startRefreshing()

        XCTAssertFalse(started)
    }

    // MARK: - Token refresh tests

    /// N.B. Testing timers is tricky
    func testTokenRefresh() async throws {
        currentDate = updatedAt.addingTimeInterval(59.8)

        let tokenA = ConferenceToken.randomToken(updatedAt: updatedAt)
        let tokenB = tokenA.updating(
            value: UUID().uuidString,
            expires: "120",
            updatedAt: currentDate
        )

        service.refreshTokenResult = .success(
            TokenRefreshResponse(
                token: tokenB.value,
                expires: tokenB.expiresString
            )
        )

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
        let tokenA = ConferenceToken.randomToken(updatedAt: updatedAt)
        var refreshError: Error?

        currentDate = updatedAt.addingTimeInterval(60)
        service.refreshTokenResult = .failure(URLError(.badURL))

        // 1. Start refreshing to schedule token refresh
        try await store.updateToken(tokenA)
        await refresher.startRefreshing(onError: { error in
            refreshError = error
        })

        let tokenFromStore1 = try await store.token()
        let isRefreshing1 = await refresher.isRefreshing

        XCTAssertEqual(tokenFromStore1, tokenA)
        XCTAssertTrue(isRefreshing1)

        // 2. Wait for token refresh
        try await Task.sleep(seconds: 0.1)

        let tokenFromStore2 = try await store.token()
        let isRefreshing2 = await refresher.isRefreshing

        XCTAssertEqual(service.steps, [.refreshToken])
        XCTAssertEqual(tokenFromStore2, tokenA)
        XCTAssertEqual(refreshError as? URLError, URLError(.badURL))
        XCTAssertFalse(isRefreshing2)
    }

    func testTokenRefreshWithExpiredToken() async throws {
        let tokenA = ConferenceToken.randomToken(updatedAt: updatedAt.addingTimeInterval(-240))

        currentDate = updatedAt.addingTimeInterval(60)

        // 1. Activate refresher and schedule token refresh
        try await store.updateToken(tokenA)

        do {
            await refresher.startRefreshing()
            _ = try await store.token()
        } catch {
            let isRefreshing = await refresher.isRefreshing
            XCTAssertFalse(isRefreshing)
            XCTAssertEqual(error as? InfinityTokenError, .tokenExpired)
        }
    }

    // MARK: - End refreshing tests

    func testEndRefreshingWithValidToken() async throws {
        let token = ConferenceToken.randomToken(updatedAt: updatedAt)
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
        let token = ConferenceToken.randomToken(updatedAt: updatedAt)

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
        let token = ConferenceToken.randomToken(updatedAt: updatedAt)
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
        let token = ConferenceToken.randomToken(updatedAt: updatedAt)
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

    var refreshTokenResult: Result<TokenRefreshResponse, Error> = .failure(URLError(.badURL))
    var releaseTokenResult: Result<Void, Error> = .success(())
    private(set) var steps = [Step]()

    func requestToken(
        fields: ConferenceTokenRequestFields,
        pin: String?
    ) async throws -> ConferenceToken {
        throw ConferenceTokenError.invalidPin
    }

    func refreshToken(_ token: InfinityToken) async throws -> TokenRefreshResponse {
        steps.append(.refreshToken)
        return try refreshTokenResult.get()
    }

    func releaseToken(_ token: InfinityToken) async throws {
        steps.append(.releaseToken)
        try releaseTokenResult.get()
    }
}
