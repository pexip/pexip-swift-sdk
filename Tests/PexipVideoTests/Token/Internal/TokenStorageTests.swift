import XCTest
import dnssd
@testable import PexipVideo

final class TokenStorageTests: XCTestCase {
    private var storage: TokenStorage!

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        storage = TokenStorage(token: nil)
    }

    // MARK: - Tests

    func testAuthToken() async throws {
        let token = Token.randomToken()
        try await storage.updateToken(token)
        let tokenFromStorage = try await storage.token()

        XCTAssertEqual(tokenFromStorage, token)
    }

    func testAuthTokenWithNewTokenTask() async throws {
        let token = Token.randomToken()
        let newToken = Token.randomToken()
        try await storage.updateToken(token)
        let newTokenTask = Task<Token, Error> {
            try await Task.sleep(seconds: 0.1)
            return newToken
        }
        try await storage.updateToken(withTask: newTokenTask)
        let tokenFromStorage = try await storage.token()

        XCTAssertEqual(tokenFromStorage, newToken)
    }

    func testClear() async throws {
        try await storage.updateToken(.randomToken())
        let newTokenTask = Task<Token, Error> {
            try await Task.sleep(seconds: 0.4)
            return .randomToken()
        }
        try await storage.updateToken(withTask: newTokenTask)
        await storage.clear()
        let tokenFromStorage = try await storage.token()

        XCTAssertNil(tokenFromStorage)
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
            expiresString: "\(expires)"
        )
    }
}
