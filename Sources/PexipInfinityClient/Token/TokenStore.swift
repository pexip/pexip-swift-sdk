import Foundation

public actor TokenStore<Token: InfinityToken> {
    private var token: Token
    private var updateTask: Task<Token, Error>?

    // MARK: - Init

    public init(token: Token) {
        self.token = token
    }

    // MARK: - Internal

    public func token() async throws -> Token {
        if let updateTask = updateTask {
            return try await updateTask.value
        } else {
            return token
        }
    }

    public func updateToken(_ token: Token) async throws {
        try await updateToken(withTask: Task { token })
    }

    public func updateToken(withTask task: Task<Token, Error>) async throws {
        updateTask = task
        token = try await task.value
        updateTask = nil
    }

    public func cancelUpdateIfNeeded() {
        updateTask?.cancel()
        updateTask = nil
    }
}
