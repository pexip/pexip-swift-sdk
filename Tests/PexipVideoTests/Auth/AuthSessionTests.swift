import XCTest
import dnssd
@testable import PexipVideo

final class AuthSessionTests: XCTestCase {
    private var session: AuthSession!
    private var storage: AuthStorageMock!
    private var client: AuthClientMock!
    private var calendar: Calendar!
    private var createdAt: Date!
    private var currentDate = Date()
    private let connectionDetails = ConnectionDetails(
        participantUUID: UUID(),
        displayName: "Test",
        serviceType: .conference,
        conferenceName: "Test",
        stun: nil
    )

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()

        calendar = Calendar.current
        calendar.timeZone = try XCTUnwrap(TimeZone(abbreviation: "GMT"))
        createdAt = try XCTUnwrap(
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
        storage = AuthStorageMock()
        client = AuthClientMock()
        session = AuthSession(
            client: client,
            storage: storage,
            logger: .stub,
            currentDateProvider: { [unowned self] in
                self.currentDate
            }
        )
    }

    // MARK: - Activate tests

    func testActivate() async throws {
        let token = AuthToken.randomToken(createdAt: createdAt)
        client.requestTokenResult = .success((token, connectionDetails))
        currentDate = createdAt.addingTimeInterval(60)

        try await session.activate(
            displayName: "Guest",
            pin: "123",
            conferenceExtension: "ext"
        )

        let isRefreshScheduled = await session.isRefreshScheduled
        let tokenFromStorage = try await storage.authToken()
        let connectionDetailsFromStorage = await storage.connectionDetails()

        XCTAssertFalse(storage.isClearCalled)
        XCTAssertEqual(tokenFromStorage, token)
        XCTAssertEqual(connectionDetailsFromStorage, connectionDetails)
        XCTAssertTrue(isRefreshScheduled)
        XCTAssertEqual(
            client.steps,
            [.requestToken(name: "Guest", pin: "123", ext: "ext")]
        )
    }

    func testActivateWithExistingValidToken() async throws {
        let oldToken = AuthToken.randomToken(createdAt: createdAt)
        let newToken = AuthToken.randomToken(createdAt: createdAt)

        try await storage.storeToken(oldToken)
        client.requestTokenResult = .success((newToken, connectionDetails))
        client.releaseTokenResult = .success(())
        currentDate = createdAt.addingTimeInterval(60)

        try await session.activate(displayName: "Guest")

        let isRefreshScheduled = await session.isRefreshScheduled
        let tokenFromStorage = try await storage.authToken()
        let connectionDetailsFromStorage = await storage.connectionDetails()

        XCTAssertTrue(storage.isClearCalled)
        XCTAssertEqual(tokenFromStorage, newToken)
        XCTAssertEqual(connectionDetailsFromStorage, connectionDetails)
        XCTAssertTrue(isRefreshScheduled)
        XCTAssertEqual(
            client.steps,
            [.releaseToken, .requestToken(name: "Guest", pin: nil, ext: nil)]
        )
    }

    func testActivateWithClientError() async throws {
        client.requestTokenResult = .failure(URLError(.badURL))

        do {
            try await session.activate(displayName: "Guest")
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .badURL)
        }

        let isRefreshScheduled = await session.isRefreshScheduled
        let tokenFromStorage = try await storage.authToken()
        let connectionDetailsFromStorage = await storage.connectionDetails()

        XCTAssertFalse(storage.isClearCalled)
        XCTAssertNil(tokenFromStorage)
        XCTAssertNil(connectionDetailsFromStorage)
        XCTAssertFalse(isRefreshScheduled)
        XCTAssertEqual(
            client.steps,
            [.requestToken(name: "Guest", pin: nil, ext: nil)]
        )
    }

    func testActivateWithStoreTokenError() async throws {
        let token = AuthToken.randomToken(createdAt: createdAt)
        client.requestTokenResult = .success((token, connectionDetails))
        storage.storeTokenError = URLError(.cannotOpenFile)

        do {
            try await session.activate(displayName: "Guest")
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .cannotOpenFile)
        }

        let isRefreshScheduled = await session.isRefreshScheduled
        let tokenFromStorage = try await storage.authToken()
        let connectionDetailsFromStorage = await storage.connectionDetails()

        XCTAssertFalse(storage.isClearCalled)
        XCTAssertNil(tokenFromStorage)
        XCTAssertNil(connectionDetailsFromStorage)
        XCTAssertFalse(isRefreshScheduled)
        XCTAssertEqual(
            client.steps,
            [.requestToken(name: "Guest", pin: nil, ext: nil)]
        )
    }

    // MARK: - Token refresh tests

    /// N.B. Testing timers is tricky
    func testTokenRefresh() async throws {
        let tokenA = AuthToken.randomToken(createdAt: createdAt)
        let tokenB = AuthToken.randomToken(createdAt: createdAt)

        currentDate = createdAt.addingTimeInterval(59.8)
        client.requestTokenResult = .success((tokenA, connectionDetails))
        client.refreshTokenResult = .success(tokenB)

        // 1. Activate session and schedule token refresh
        try await session.activate(displayName: "Guest")

        let tokenFromStorage = try await storage.authToken()
        let isRefreshScheduled = await session.isRefreshScheduled

        XCTAssertEqual(tokenFromStorage, tokenA)
        XCTAssertTrue(isRefreshScheduled)

        // 2. Wait to token refresh
        let waitForRefresh = Task {
            try await Task.sleep(seconds: 0.3)

            XCTAssertEqual(
                client.steps,
                [.requestToken(name: "Guest", pin: nil, ext: nil), .refreshToken]
            )

            let tokenFromStorage = try await storage.authToken()
            let isRefreshScheduled = await session.isRefreshScheduled

            XCTAssertEqual(tokenFromStorage, tokenB)
            XCTAssertTrue(isRefreshScheduled)
        }

        try await waitForRefresh.value
    }

    /// N.B. Testing timers is tricky
    func testTokenRefreshWithClientError() async throws {
        let tokenA = AuthToken.randomToken(createdAt: createdAt)

        currentDate = createdAt.addingTimeInterval(60)
        client.requestTokenResult = .success((tokenA, connectionDetails))
        client.refreshTokenResult = .failure(URLError(.badURL))

        // 1. Activate session and schedule token refresh
        try await session.activate(displayName: "Guest")

        let tokenFromStorage = try await storage.authToken()
        let isRefreshScheduled = await session.isRefreshScheduled

        XCTAssertEqual(tokenFromStorage, tokenA)
        XCTAssertTrue(isRefreshScheduled)

        // 2. Wait to token refresh
        let waitForRefresh = Task {
            try await Task.sleep(seconds: 0.1)

            XCTAssertEqual(
                client.steps,
                [.requestToken(name: "Guest", pin: nil, ext: nil), .refreshToken]
            )

            let tokenFromStorage = try await storage.authToken()
            let isRefreshScheduled = await session.isRefreshScheduled

            XCTAssertEqual(tokenFromStorage, tokenA)
            XCTAssertFalse(isRefreshScheduled)
        }

        try await waitForRefresh.value
    }

    func testTokenRefreshWithExpiredToken() async throws {
        let tokenA = AuthToken.randomToken(createdAt: createdAt.addingTimeInterval(-240))
        let tokenB = AuthToken.randomToken(createdAt: createdAt)

        currentDate = createdAt.addingTimeInterval(60)
        client.requestTokenResult = .success((tokenA, connectionDetails))
        client.refreshTokenResult = .success(tokenB)

        // 1. Activate session and schedule token refresh
        try await session.activate(displayName: "Guest")

        let tokenFromStorage = try await storage.authToken()
        let isRefreshScheduled = await session.isRefreshScheduled

        XCTAssertEqual(tokenFromStorage, tokenA)
        XCTAssertFalse(isRefreshScheduled)
    }

    // MARK: - Deactivate tests

    func testDeactivateWithExistingValidToken() async throws {
        let token = AuthToken.randomToken(createdAt: createdAt)

        client.releaseTokenResult = .success(())
        currentDate = createdAt.addingTimeInterval(60)

        try await storage.storeToken(token)
        try await session.deactivate()

        let isRefreshScheduled = await session.isRefreshScheduled

        XCTAssertFalse(isRefreshScheduled)
        XCTAssertTrue(storage.isClearCalled)
        XCTAssertEqual(client.steps, [.releaseToken])
    }

    func testDeactivateWithClientError() async throws {
        let token = AuthToken.randomToken(createdAt: createdAt)

        client.requestTokenResult = .failure(URLError(.badURL))
        currentDate = createdAt.addingTimeInterval(60)

        try await storage.storeToken(token)

        do {
            try await session.deactivate()
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .badURL)
        }

        let isRefreshScheduled = await session.isRefreshScheduled

        XCTAssertFalse(isRefreshScheduled)
        XCTAssertTrue(storage.isClearCalled)
        XCTAssertEqual(client.steps, [.releaseToken])
    }

    func testDeactivateWithExistingExpiredToken() async throws {
        let token = AuthToken.randomToken(createdAt: createdAt)
        currentDate = createdAt.addingTimeInterval(120)

        try await storage.storeToken(token)
        try await session.deactivate()

        let isRefreshScheduled = await session.isRefreshScheduled

        XCTAssertFalse(isRefreshScheduled)
        XCTAssertTrue(storage.isClearCalled)
        XCTAssertTrue(client.steps.isEmpty)
    }

    func testDeactivateWithoutExistingToken() async throws {
        try await session.deactivate()

        let isRefreshScheduled = await session.isRefreshScheduled

        XCTAssertFalse(isRefreshScheduled)
        XCTAssertTrue(storage.isClearCalled)
        XCTAssertTrue(client.steps.isEmpty)
    }
}

// MARK: - Mocks

private final class AuthClientMock: AuthClientProtocol {
    typealias RequestTokenResult = Result<(AuthToken, ConnectionDetails), Error>

    enum Step: Equatable {
        case requestToken(name: String, pin: String?, ext: String?)
        case refreshToken
        case releaseToken
    }

    var requestTokenResult: RequestTokenResult = .failure(URLError(.badURL))
    var refreshTokenResult: Result<AuthToken, Error> = .failure(URLError(.badURL))
    var releaseTokenResult: Result<Void, Error> = .failure(URLError(.badURL))
    private(set) var steps = [Step]()

    func requestToken(
        displayName: String,
        pin: String?,
        conferenceExtension: String?
    ) async throws -> (AuthToken, ConnectionDetails) {
        steps.append(.requestToken(name: displayName, pin: pin, ext: conferenceExtension))
        return try requestTokenResult.get()
    }

    func refreshToken(_ token: AuthToken) async throws -> AuthToken {
        steps.append(.refreshToken)
        return try refreshTokenResult.get()
    }

    func releaseToken(_ token: AuthToken) async throws {
        steps.append(.releaseToken)
        try releaseTokenResult.get()
    }
}

private final class AuthStorageMock: AuthStorageProtocol {
    var storeTokenError: Error?
    private(set) var isClearCalled = false
    private var token: AuthToken?
    private var connectionDetails: ConnectionDetails?

    func storeToken(withTask task: Task<AuthToken, Error>) async throws {
        if let storeTokenError = storeTokenError {
            throw storeTokenError
        }
        token = try await task.value
    }

    func connectionDetails() async -> ConnectionDetails? {
        return connectionDetails
    }

    func storeConnectionDetails(_ details: ConnectionDetails) async {
        connectionDetails = details
    }

    func clear() async {
        isClearCalled = true
    }

    func authToken() async throws -> AuthToken? {
        return token
    }
}
