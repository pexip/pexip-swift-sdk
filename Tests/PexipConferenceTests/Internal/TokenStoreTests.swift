import XCTest
@testable import PexipInfinityClient
@testable import PexipConference

final class TokenStoreTests: XCTestCase {
    private var store: TokenStore!

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        store = DefaultTokenStore(token: .randomToken())
    }

    // MARK: - Tests

    func testToken() async throws {
        let newToken = Token.randomToken()
        try await store.updateToken(newToken)
        let tokenFromStore = try await store.token()

        XCTAssertEqual(tokenFromStore, newToken)
    }

    func testTokenWithNewTokenTask() async throws {
        let token = Token.randomToken()
        let newToken = Token.randomToken()
        try await store.updateToken(token)
        let newTokenTask = Task<Token, Error> {
            try await Task.sleep(seconds: 0.1)
            return newToken
        }
        try await store.updateToken(withTask: newTokenTask)
        let tokenFromStorage = try await store.token()

        XCTAssertEqual(tokenFromStorage, newToken)
    }

    func testDeinit() async throws {
        var store: TokenStore? = DefaultTokenStore(token: .randomToken())
        let newTokenTask = Task<Token, Error> {
            try await Task.sleep(seconds: 0.4)
            return .randomToken()
        }
        try await store?.updateToken(withTask: newTokenTask)
        store = nil

        XCTAssertTrue(newTokenTask.isCancelled)
    }
}

// MARK: - Stubs

extension Token {
    static func randomToken(
        updatedAt: Date = .init(),
        expires: TimeInterval = 120,
        stun: [String] = []
    ) -> Token {
        Token(
            value: UUID().uuidString,
            updatedAt: updatedAt,
            participantId: UUID(),
            role: .guest,
            displayName: "Guest",
            serviceType: "conference",
            conferenceName: "Test",
            stun: stun.map(Token.Stun.init(url:)),
            turn: [],
            chatEnabled: true,
            analyticsEnabled: true,
            expiresString: "\(expires)"
        )
    }
}
