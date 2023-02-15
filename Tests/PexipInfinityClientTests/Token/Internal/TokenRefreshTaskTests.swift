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

import XCTest
import Combine
@testable import PexipInfinityClient

// swiftlint:disable type_body_length file_length
final class TokenRefreshTaskTests: XCTestCase {
    private var task: TokenRefreshTask!
    private var store: TokenStore<ConferenceToken>!
    private var service: TokenServiceMock!
    private var calendar: Calendar!
    private var updatedAt: Date!
    private var currentDate = Date()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Setup

    // swiftlint:disable unowned_variable_capture
    override func setUpWithError() throws {
        try super.setUpWithError()

        calendar = Calendar.current
        calendar.timeZone = try XCTUnwrap(TimeZone(abbreviation: "GMT"))
        updatedAt = try XCTUnwrap(
            DateComponents(
                calendar: calendar,
                year: 2022,
                month: 1,
                day: 27,
                hour: 13,
                minute: 16,
                second: 11
            ).date
        )
        store = TokenStore(
            token: .randomToken(),
            currentDateProvider: { [unowned self] in
                self.currentDate
            }
        )
        service = TokenServiceMock()
    }

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - Tests

    func testTokenRefresh() throws {
        // 1. Prepare
        currentDate = updatedAt.addingTimeInterval(59.9)

        let expectationA = self.expectation(description: "Token store")
        let tokenA = ConferenceToken.randomToken(updatedAt: updatedAt)
        let tokenB = tokenA.updating(
            value: UUID().uuidString,
            expires: "0.1",
            updatedAt: currentDate
        )

        service.refreshTokenResult = .success(
            TokenRefreshResponse(token: tokenB.value, expires: tokenB.expiresString)
        )

        Task {
            try await store.updateToken(tokenA)
            expectationA.fulfill()
        }

        wait(for: [expectationA], timeout: 1)

        // 2. Schedule token refresh
        let expectationB = self.expectation(description: "Token refresh")
        var numberOfUpdates = 0
        task = createTask()

        // 3. Wait for 2 token refreshes
        task.eventPublisher.sink { event in
            switch event {
            case .tokenUpdated:
                numberOfUpdates += 1

                if numberOfUpdates == 1 {
                    XCTAssertEqual(self.service.steps, [.refreshToken])
                } else if numberOfUpdates == 2 {
                    XCTAssertEqual(self.service.steps, [.refreshToken, .refreshToken])
                    Task {
                        let tokenFromStore = try await self.store.token()
                        XCTAssertEqual(tokenFromStore, tokenB)
                        expectationB.fulfill()
                    }
                }
            default:
                XCTFail("Unexpected token refresh event: \(event).")
            }
        }.store(in: &cancellables)

        wait(for: [expectationB], timeout: 1)
    }

    func testTokenRefreshWithServiceError() throws {
        // 1. Prepare
        let expectationA = self.expectation(description: "Token store")
        let tokenA = ConferenceToken.randomToken(updatedAt: updatedAt)
        currentDate = updatedAt.addingTimeInterval(59.9)
        service.refreshTokenResult = .failure(URLError(.badURL))

        Task {
            try await store.updateToken(tokenA)
            expectationA.fulfill()
        }

        wait(for: [expectationA], timeout: 0.3)

        // 2. Schedule token refresh
        let expectationB = self.expectation(description: "Token refresh")
        task = createTask()

        // 3. Wait for events
        task.eventPublisher.sink { event in
            switch event {
            case .failed(let error):
                XCTAssertEqual(self.service.steps, [.refreshToken])
                XCTAssertEqual(error as? URLError, URLError(.badURL))
                expectationB.fulfill()
            default:
                XCTFail("Unexpected token refresh event.")
            }
        }.store(in: &cancellables)

        wait(for: [expectationB], timeout: 0.3)
    }

    func testTokenRefreshWithExpiredToken() throws {
        // 1. Prepare
        let expectationA = self.expectation(description: "Token store")
        let tokenA = ConferenceToken.randomToken(
            updatedAt: updatedAt.addingTimeInterval(-240)
        )
        currentDate = updatedAt.addingTimeInterval(60)

        Task {
            try await store.updateToken(tokenA)
            expectationA.fulfill()
        }

        wait(for: [expectationA], timeout: 0.3)

        // 2. Schedule token refresh
        let expectationB = XCTestExpectation(description: "Token refresh")
        task = createTask()

        // 3. Wait for events
        task.eventPublisher.sink { event in
            switch event {
            case .failed(let error):
                XCTAssertEqual(error as? InfinityTokenError, .tokenExpired)
                expectationB.fulfill()
            default:
                XCTFail("Unexpected token refresh event.")
            }
        }.store(in: &cancellables)

        wait(for: [expectationB], timeout: 0.3)

        XCTAssertTrue(service.steps.isEmpty)
    }

    func testCancel() throws {
        // 1. Prepare
        let expectationA = self.expectation(description: "Token store")
        let token = ConferenceToken.randomToken(updatedAt: updatedAt)
        currentDate = updatedAt.addingTimeInterval(10)

        Task {
            try await store.updateToken(token)
            expectationA.fulfill()
        }

        wait(for: [expectationA], timeout: 0.3)

        // 2. Schedule refresh
        task = createTask()
        let expectationB = self.expectation(description: "Cancel")

        // 3. Cancel and wait for events
        task.eventPublisher.sink { event in
            switch event {
            case .failed(let error):
                XCTAssertTrue(error is CancellationError)
                XCTAssertTrue(self.service.steps.isEmpty)
                expectationB.fulfill()
            default:
                XCTFail("Unexpected token refresh event.")
            }
        }.store(in: &cancellables)

        task.cancel()
        wait(for: [expectationB], timeout: 0.3)
    }

    func testCancelAndRelease() throws {
        // 1. Prepare
        let expectationA = self.expectation(description: "Token store")
        let token = ConferenceToken.randomToken(updatedAt: updatedAt)
        service.releaseTokenResult = .success(())
        currentDate = updatedAt.addingTimeInterval(10)

        Task {
            try await store.updateToken(token)
            expectationA.fulfill()
        }

        wait(for: [expectationA], timeout: 0.3)

        // 2. Schedule refresh
        task = createTask()
        let expectationB = self.expectation(description: "Token release")
        var isCancelled = false
        var isTokenReleased = false

        // 3. Cancel and wait for events
        task.eventPublisher.sink { event in
            switch event {
            case .failed(let error):
                isCancelled = error is CancellationError
            case .tokenReleased:
                isTokenReleased = true
            default:
                XCTFail("Unexpected token refresh event.")
            }

            if isCancelled && isTokenReleased {
                XCTAssertEqual(self.service.steps, [.releaseToken])
                expectationB.fulfill()
            }
        }.store(in: &cancellables)

        task.cancelAndRelease()
        wait(for: [expectationB], timeout: 0.3)
    }

    func testCancelAndReleaseWithServiceError() throws {
        // 1. Prepare
        let expectationA = self.expectation(description: "Token store")
        let token = ConferenceToken.randomToken(updatedAt: updatedAt)
        service.releaseTokenResult = .failure(URLError(.badURL))
        currentDate = updatedAt.addingTimeInterval(10)

        Task {
            try await store.updateToken(token)
            expectationA.fulfill()
        }

        wait(for: [expectationA], timeout: 0.3)

        // 2. Schedule refresh
        task = createTask()
        let expectationB = self.expectation(description: "Error")
        var isCancelled = false
        var isServiceError = false
        var numberOfErrors = 0

        // 3. Cancel and wait for events
        task.eventPublisher.sink { event in
            switch event {
            case .failed(let error):
                numberOfErrors += 1

                if error is CancellationError {
                    isCancelled = true
                } else if error as? URLError == URLError(.badURL) {
                    isServiceError = true
                }
            default:
                XCTFail("Unexpected token refresh event.")
            }

            if numberOfErrors == 2 {
                XCTAssertTrue(isCancelled)
                XCTAssertTrue(isServiceError)
                XCTAssertEqual(self.service.steps, [.releaseToken])
                expectationB.fulfill()
            }
        }.store(in: &cancellables)

        task.cancelAndRelease()
        wait(for: [expectationB], timeout: 0.3)
    }

    func testCancelAndReleaseWithExpiredToken() throws {
        // 1. Prepare
        let expectationA = self.expectation(description: "Token store")
        let token = ConferenceToken.randomToken(updatedAt: updatedAt)
        currentDate = updatedAt.addingTimeInterval(10)

        Task {
            try await store.updateToken(token)
            expectationA.fulfill()
        }

        wait(for: [expectationA], timeout: 0.3)

        // 2. Schedule refresh
        let expectationB = self.expectation(description: "Schedule refresh")
        task = createTask()

        Task {
            try await Task.sleep(seconds: 0.1)
            expectationB.fulfill()
        }

        wait(for: [expectationB], timeout: 0.3)

        // 3. Make the token expired
        let expectationC = self.expectation(description: "Error")
        var isCancelled = false
        var isTokenError = false
        var numberOfErrors = 0
        currentDate = updatedAt.addingTimeInterval(120)

        // 4. Cancel and wait for events
        task.eventPublisher.sink { event in
            switch event {
            case .failed(let error):
                numberOfErrors += 1

                if error is CancellationError {
                    isCancelled = true
                } else if error as? InfinityTokenError == .tokenExpired {
                    isTokenError = true
                }
            default:
                XCTFail("Unexpected token refresh event.")
            }

            if numberOfErrors == 2 {
                XCTAssertTrue(isCancelled)
                XCTAssertTrue(isTokenError)
                XCTAssertTrue(self.service.steps.isEmpty)
                expectationC.fulfill()
            }
        }.store(in: &cancellables)

        task.cancelAndRelease()
        wait(for: [expectationC], timeout: 0.3)
    }

    // MARK: - Test helpers

    private func createTask() -> TokenRefreshTask {
        DefaultTokenRefreshTask(
            store: store,
            service: service,
            currentDate: { [unowned self] in
                self.currentDate
            }
        )
    }
}

// MARK: - Mocks

private final class TokenServiceMock: TokenService {
    enum Step: Equatable {
        case refreshToken
        case releaseToken
    }

    var refreshTokenResult: Result<TokenRefreshResponse, Error> = .failure(URLError(.badURL))
    var releaseTokenResult: Result<Void, Error> = .success(())
    private(set) var steps = [Step]()

    func requestToken(
        fields: ConferenceTokenRequestFields,
        pin: String?
    ) async throws -> ConferenceToken {
        throw ConferenceTokenError.invalidPin
    }

    func refreshToken(_ token: InfinityToken) async throws -> TokenRefreshResponse {
        steps.append(.refreshToken)
        return try refreshTokenResult.get()
    }

    func releaseToken(_ token: InfinityToken) async throws {
        steps.append(.releaseToken)
        try releaseTokenResult.get()
    }
}
