import Foundation
import PexipInfinityClient

// MARK: - Protocols

protocol TokenStore {
    func token() async throws -> Token
    func updateToken(withTask task: Task<Token, Error>) async throws
}

extension TokenStore {
    func updateToken(_ token: Token) async throws {
        try await updateToken(withTask: Task { token })
    }
}

// MARK: - Implementation

actor DefaultTokenStore: TokenStore {
    private var token: Token
    private var updateTask: Task<Token, Error>?

    // MARK: - Init

    init(token: Token) {
        self.token = token
    }

    deinit {
        cancelUpdateTask()
    }

    // MARK: - TokenStore

    func token() async throws -> Token {
        guard let updateTask = updateTask else {
            return token
        }

        let token = try await updateTask.value
        self.updateTask = nil
        return token
    }

    func updateToken(withTask task: Task<Token, Error>) async throws {
        updateTask = task
    }

    // MARK: - Private

    private func cancelUpdateTask() {
        updateTask?.cancel()
        updateTask = nil
    }
}
