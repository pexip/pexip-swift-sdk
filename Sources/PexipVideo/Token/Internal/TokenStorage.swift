import Foundation

// MARK: - Protocols

protocol TokenProvider: AnyObject {
    func token() async throws -> Token?
}

protocol TokenStorageProtocol: TokenProvider {
    func updateToken(withTask task: Task<Token, Error>) async throws
    func clear() async
}

extension TokenStorageProtocol {
    func updateToken(_ token: Token) async throws {
        try await updateToken(withTask: Task { token })
    }
}

// MARK: - Implementation

actor TokenStorage: TokenStorageProtocol {
    private var token: Token?
    private var updateTask: Task<Token, Error>?

    // MARK: - Init

    init(token: Token?) {
        self.token = token
    }

    deinit {
        cancelUpdateTask()
    }

    // MARK: - Auth token

    func token() async throws -> Token? {
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

    // MARK: - Clean up

    func clear() async {
        cancelUpdateTask()
        token = nil
    }

    private func cancelUpdateTask() {
        updateTask?.cancel()
        updateTask = nil
    }
}
