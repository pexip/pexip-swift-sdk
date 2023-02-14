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
import Combine
import PexipCore

// MARK: - Protocol

enum TokenRefreshTaskEvent {
    case tokenUpdated
    case tokenReleased
    case failed(Error)
}

protocol TokenRefreshTask {
    var eventPublisher: AnyPublisher<TokenRefreshTaskEvent, Never> { get }
    func cancel()
    func cancelAndRelease()
}

// MARK: - Implementaion

final class DefaultTokenRefreshTask<Token: InfinityToken>: TokenRefreshTask {
    var eventPublisher: AnyPublisher<TokenRefreshTaskEvent, Never> {
        subject.compactMap({ $0 }).eraseToAnyPublisher()
    }

    private let service: TokenService
    private let store: TokenStore<Token>
    private let logger: Logger?
    private let currentDate: () -> Date
    private var task: Task<Void, Never>!
    private let subject: CurrentValueSubject<TokenRefreshTaskEvent?, Never>

    // MARK: - Init

    init(
        store: TokenStore<Token>,
        service: TokenService,
        logger: Logger? = nil,
        currentDate: @escaping () -> Date = { Date() }
    ) {
        self.service = service
        self.store = store
        self.logger = logger
        self.currentDate = currentDate
        self.subject = CurrentValueSubject<TokenRefreshTaskEvent?, Never>(nil)

        task = Task {
            func refresh() async throws {
                let token = try await store.token()
                let seconds = token.refreshDate.timeIntervalSince(currentDate())

                try await Task.sleep(seconds: seconds)
                try Task.checkCancellation()

                logger?.debug("Refreshing a \(Token.name) to get a new one...")

                try await store.updateToken(withTask: Task {
                    let response = try await service.refreshToken(token)
                    logger?.debug("New \(Token.name) received 👌")
                    try Task.checkCancellation()

                    return token.updating(
                        value: response.token,
                        expires: response.expires,
                        updatedAt: currentDate()
                    )
                })

                subject.send(.tokenUpdated)
                try Task.checkCancellation()
                try await refresh()
            }

            do {
                logger?.info("\(Token.name) refresh operation started ✅")
                try await refresh()
            } catch {
                subject.send(.failed(error))
            }
        }
    }

    deinit {
        cancel()
    }

    // MARK: - TokenRefreshTask

    func cancel() {
        guard !task.isCancelled else {
            return
        }

        task.cancel()
        logger?.info("\(Token.name) refresh operation cancelled ⛔️")
    }

    func cancelAndRelease() {
        cancel()

        Task {
            do {
                let token = try await store.token()

                if !token.isExpired(currentDate: currentDate()) {
                    logger?.debug("Releasing the \(Token.name)...")
                    try await service.releaseToken(token)
                    subject.send(.tokenReleased)
                }
            } catch {
                logger?.error("Error on \(Token.name) release: \(error)")
                subject.send(.failed(error))
            }
        }
    }
}
