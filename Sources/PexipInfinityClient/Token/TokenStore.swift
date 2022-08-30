import Foundation

public actor TokenStore<Token: InfinityToken> {
    private var token: Token
    private var updateTask: Task<Token, Error>?
    private let currentDate: () -> Date

    // MARK: - Init

    public init(
        token: Token,
        currentDateProvider: @escaping () -> Date = { Date() }
    ) {
        self.token = token
        self.currentDate = currentDateProvider
    }

    // MARK: - Internal

    public func token() async throws -> Token {
        let token: Token

        if let updateTask = updateTask {
            token = try await updateTask.value
        } else {
            token = self.token
        }

        if token.isExpired(currentDate: currentDate()) {
            throw InfinityTokenError.tokenExpired
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
