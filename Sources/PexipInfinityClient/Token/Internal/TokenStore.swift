import Foundation

actor TokenStore<Token: InfinityToken> {
    private var token: Token
    private var updateTask: Task<Token, Error>?
    private let currentDate: () -> Date

    // MARK: - Init

    init(
        token: Token,
        currentDateProvider: @escaping () -> Date = { Date() }
    ) {
        self.token = token
        self.currentDate = currentDateProvider
    }

    // MARK: - Internal

    func token() async throws -> Token {
        let token: Token

        if let updateTask = updateTask {
            token = try await updateTask.value
        } else {
            token = self.token
        }

        guard !token.isExpired(currentDate: currentDate()) else {
            throw InfinityTokenError.tokenExpired
        }

        return token
    }

    func updateToken(_ token: Token) async throws {
        try await updateToken(withTask: Task { token })
    }

    func updateToken(withTask task: Task<Token, Error>) async throws {
        updateTask = task
        token = try await task.value
        updateTask = nil
    }

    func cancelUpdateIfNeeded() {
        updateTask?.cancel()
        updateTask = nil
    }
}
