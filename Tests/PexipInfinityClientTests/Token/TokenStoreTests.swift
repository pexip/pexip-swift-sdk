import XCTest
@testable import PexipInfinityClient

final class TokenStoreTests: XCTestCase {
    private var store: TokenStore<ConferenceToken>!

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        store = TokenStore(token: .randomToken())
    }

    // MARK: - Tests

    func testToken() async throws {
        let newToken = ConferenceToken.randomToken()
        try await store.updateToken(newToken)
        let tokenFromStore1 = try await store.token()
        let tokenFromStore2 = try await store.token()

        XCTAssertEqual(tokenFromStore1, newToken)
        XCTAssertEqual(tokenFromStore2, newToken)
    }

    func testTokenWithNewTokenTask() async throws {
        let token = ConferenceToken.randomToken()
        let newToken = ConferenceToken.randomToken()
        try await store.updateToken(token)
        let newTokenTask = Task<ConferenceToken, Error> {
            try await Task.sleep(seconds: 0.1)
            return newToken
        }
        try await store.updateToken(withTask: newTokenTask)
        let tokenFromStore1 = try await store.token()
        let tokenFromStore2 = try await store.token()

        XCTAssertEqual(tokenFromStore1, newToken)
        XCTAssertEqual(tokenFromStore2, newToken)
    }

    func testTokenWithError() async throws {
        let token = ConferenceToken.randomToken()
        try await store.updateToken(token)
        let newTokenTask = Task<ConferenceToken, Error> {
            throw ConferenceTokenError.tokenDecodingFailed
        }

        // 1. Update token with error
        do {
            try await store.updateToken(withTask: newTokenTask)
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? ConferenceTokenError, .tokenDecodingFailed)
        }

        // 2. Try to get the token from the store
        do {
            _ = try await store.token()
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? ConferenceTokenError, .tokenDecodingFailed)
        }
    }

    func testCancelUpdateIfNeeded() async throws {
        let token = ConferenceToken.randomToken()
        try await store.updateToken(token)
        let newTokenTask = Task<ConferenceToken, Error> {
            throw ConferenceTokenError.tokenDecodingFailed
        }

        // 1. Update token with error
        do {
            try await store.updateToken(withTask: newTokenTask)
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? ConferenceTokenError, .tokenDecodingFailed)
        }

        // 2. Cancel the update task
        await store.cancelUpdateIfNeeded()

        // 3. Try to get the token from the store
        let tokenFromStore = try await store.token()
        XCTAssertEqual(tokenFromStore, token)
        XCTAssertTrue(newTokenTask.isCancelled)
    }
}
