import XCTest
import dnssd
@testable import PexipVideo

final class TokenSessionTests: XCTestCase {
    private var session: TokenSession!
    private var storage: TokenStorageMock!
    private var client: TokenClientMock!
    private var calendar: Calendar!
    private var updatedAt: Date!
    private var currentDate = Date()

    // MARK: - Setup

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
        storage = TokenStorageMock()
        client = TokenClientMock()
        session = TokenSession(
            client: client,
            storage: storage,
            logger: SilentLogger(),
            currentDateProvider: { [unowned self] in
                self.currentDate
            }
        )
    }

    // MARK: - Activate tests

    func testActivate() async throws {
        let token = Token.randomToken(updatedAt: updatedAt)
        currentDate = updatedAt.addingTimeInterval(60)

        try await storage.updateToken(token)
        await session.activate()

        let isRefreshScheduled = await session.isRefreshScheduled
        let tokenFromStorage = try await storage.token()

        XCTAssertEqual(tokenFromStorage, token)
        XCTAssertTrue(isRefreshScheduled)
        XCTAssertTrue(client.steps.isEmpty)
    }

    func testActivateWithoutToken() async throws {
        let activated = await session.activate()
        XCTAssertFalse(activated)
    }

    func testActivateWhenDeactivated() async throws {
        try await storage.updateToken(Token.randomToken())
        await session.activate()
        await session.deactivate(releaseToken: true)
        let activated = await session.activate()

        XCTAssertFalse(activated)
    }

    func testActivateWhenActive() async throws {
        try await storage.updateToken(Token.randomToken())
        await session.activate()
        let activated = await session.activate()

        XCTAssertFalse(activated)
    }

    // MARK: - Token refresh tests

    /// N.B. Testing timers is tricky
    func testTokenRefresh() async throws {
        let tokenA = Token.randomToken(updatedAt: updatedAt)
        let tokenB = Token.randomToken(updatedAt: updatedAt)

        currentDate = updatedAt.addingTimeInterval(59.8)
        client.refreshTokenResult = .success(tokenB)

        // 1. Activate session and schedule token refresh
        try await storage.updateToken(tokenA)
        await session.activate()

        let tokenFromStorage = try await storage.token()
        let isRefreshScheduled = await session.isRefreshScheduled

        XCTAssertEqual(tokenFromStorage, tokenA)
        XCTAssertTrue(isRefreshScheduled)

        // 2. Wait to token refresh
        let waitForRefresh = Task {
            try await Task.sleep(seconds: 0.3)

            XCTAssertEqual(client.steps, [.refreshToken])

            let tokenFromStorage = try await storage.token()
            let isRefreshScheduled = await session.isRefreshScheduled

            XCTAssertEqual(tokenFromStorage, tokenB)
            XCTAssertTrue(isRefreshScheduled)
        }

        try await waitForRefresh.value
    }

    /// N.B. Testing timers is tricky
    func testTokenRefreshWithClientError() async throws {
        let tokenA = Token.randomToken(updatedAt: updatedAt)

        currentDate = updatedAt.addingTimeInterval(60)
        client.refreshTokenResult = .failure(URLError(.badURL))

        // 1. Activate session and schedule token refresh
        try await storage.updateToken(tokenA)
        await session.activate()

        let tokenFromStorage = try await storage.token()
        let isRefreshScheduled = await session.isRefreshScheduled

        XCTAssertEqual(tokenFromStorage, tokenA)
        XCTAssertTrue(isRefreshScheduled)

        // 2. Wait to token refresh
        let waitForRefresh = Task {
            try await Task.sleep(seconds: 0.1)

            XCTAssertEqual(client.steps, [.refreshToken])

            let tokenFromStorage = try await storage.token()
            let isRefreshScheduled = await session.isRefreshScheduled

            XCTAssertEqual(tokenFromStorage, tokenA)
            XCTAssertFalse(isRefreshScheduled)
        }

        try await waitForRefresh.value
    }

    func testTokenRefreshWithExpiredToken() async throws {
        let tokenA = Token.randomToken(updatedAt: updatedAt.addingTimeInterval(-240))
        let tokenB = Token.randomToken(updatedAt: updatedAt)

        currentDate = updatedAt.addingTimeInterval(60)
        client.refreshTokenResult = .success(tokenB)

        // 1. Activate session and schedule token refresh
        try await storage.updateToken(tokenA)
        await session.activate()

        let tokenFromStorage = try await storage.token()
        let isRefreshScheduled = await session.isRefreshScheduled

        XCTAssertEqual(tokenFromStorage, tokenA)
        XCTAssertFalse(isRefreshScheduled)
    }

    // MARK: - Deactivate tests

    func testDeactivateWithExistingValidToken() async throws {
        let token = Token.randomToken(updatedAt: updatedAt)
        client.releaseTokenResult = .success(())
        currentDate = updatedAt.addingTimeInterval(60)

        try await storage.updateToken(token)
        await session.activate()
        let deactivated = await session.deactivate(releaseToken: true)
        let isRefreshScheduled = await session.isRefreshScheduled

        XCTAssertTrue(deactivated)
        XCTAssertFalse(isRefreshScheduled)
        XCTAssertTrue(storage.isClearCalled)
        XCTAssertEqual(client.steps, [.releaseToken])
    }

    func testDeactivateWithClientError() async throws {
        let token = Token.randomToken(updatedAt: updatedAt)

        client.releaseTokenResult = .failure(URLError(.badURL))
        currentDate = updatedAt.addingTimeInterval(60)

        try await storage.updateToken(token)
        await session.activate()
        let deactivated = await session.deactivate(releaseToken: true)
        let isRefreshScheduled = await session.isRefreshScheduled

        XCTAssertTrue(deactivated)
        XCTAssertFalse(isRefreshScheduled)
        XCTAssertTrue(storage.isClearCalled)
        XCTAssertEqual(client.steps, [.releaseToken])
    }

    func testDeactivateWithExistingExpiredToken() async throws {
        let token = Token.randomToken(updatedAt: updatedAt)
        try await storage.updateToken(token)
        currentDate = updatedAt.addingTimeInterval(60)
        await session.activate()
        currentDate = updatedAt.addingTimeInterval(120)
        let deactivated = await session.deactivate(releaseToken: true)
        let isRefreshScheduled = await session.isRefreshScheduled

        XCTAssertTrue(deactivated)
        XCTAssertFalse(isRefreshScheduled)
        XCTAssertTrue(storage.isClearCalled)
        XCTAssertTrue(client.steps.isEmpty)
    }

    func testDeactivateWithoutExistingToken() async throws {
        try await storage.updateToken(.randomToken())
        await session.activate()
        await storage.clear()

        let deactivated = await session.deactivate(releaseToken: true)
        let isRefreshScheduled = await session.isRefreshScheduled

        XCTAssertTrue(deactivated)
        XCTAssertFalse(isRefreshScheduled)
        XCTAssertTrue(client.steps.isEmpty)
    }

    func testDeactivateWhenDeactivated() async throws {
        let deactivated = await session.deactivate(releaseToken: true)
        XCTAssertFalse(deactivated)
    }

    func testDeactivateWithoutTokenRelease() async throws {
        let token = Token.randomToken(updatedAt: updatedAt)
        client.releaseTokenResult = .success(())
        currentDate = updatedAt.addingTimeInterval(60)

        try await storage.updateToken(token)
        await session.activate()
        let deactivated = await session.deactivate(releaseToken: false)
        let isRefreshScheduled = await session.isRefreshScheduled

        XCTAssertTrue(deactivated)
        XCTAssertFalse(isRefreshScheduled)
        XCTAssertTrue(storage.isClearCalled)
        XCTAssertTrue(client.steps.isEmpty)
    }
}

// MARK: - Mocks

private final class TokenClientMock: TokenManagerClientProtocol {
    enum Step: Equatable {
        case refreshToken
        case releaseToken
    }

    var refreshTokenResult: Result<Token, Error> = .failure(URLError(.badURL))
    var releaseTokenResult: Result<Void, Error> = .success(())
    private(set) var steps = [Step]()

    func refreshToken(_ token: Token) async throws -> Token {
        steps.append(.refreshToken)
        return try refreshTokenResult.get()
    }

    func releaseToken(_ token: Token) async throws {
        steps.append(.releaseToken)
        try releaseTokenResult.get()
    }
}

private final class TokenStorageMock: TokenStorageProtocol {
    var updateTokenError: Error?
    private(set) var isClearCalled = false
    private var token: Token?

    func updateToken(withTask task: Task<Token, Error>) async throws {
        if let updateTokenError = updateTokenError {
            throw updateTokenError
        }
        token = try await task.value
    }

    func clear() async {
        token = nil
        isClearCalled = true
    }

    func token() async throws -> Token? {
        return token
    }
}
