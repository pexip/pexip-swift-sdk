//
// Copyright 2022 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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

        if let updateTask {
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
