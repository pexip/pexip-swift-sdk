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
import PexipCore

// MARK: - Protocols

/// Represents the registration control functions section.
public protocol RegistrationService: TokenService {
    /**
     Requests a token for the registration alias.

     - Parameters:
        - username: A username
        - password: A password
     - Returns: A registration token
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func requestToken(username: String, password: String) async throws -> RegistrationToken

    /// HTTP EventSource which feeds server sent events as they occur.
    func eventSource() -> RegistrationEventService
}

// MARK: - Implementation

struct DefaultRegistrationService: RegistrationService {
    let baseURL: URL
    let client: HTTPClient
    var decoder = JSONDecoder()
    var logger: Logger?

    func requestToken(username: String, password: String) async throws -> RegistrationToken {
        guard !username.isEmpty, !password.isEmpty else {
            throw ValidationError.invalidArgument
        }

        var request = URLRequest(
            url: baseURL.appendingPathComponent("request_token"),
            httpMethod: .POST
        )

        request.setHTTPHeader(.authorization(username: username, password: password))

        return try await client.json(for: request)
    }

    func refreshToken(_ token: InfinityToken) async throws -> TokenRefreshResponse {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("refresh_token"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        return try await client.json(for: request)
    }

    func releaseToken(_ token: InfinityToken) async throws {
        var request = URLRequest(
            url: baseURL.appendingPathComponent("release_token"),
            httpMethod: .POST
        )
        request.setHTTPHeader(.token(token.value))
        _ = try await client.data(for: request)
    }

    func eventSource() -> RegistrationEventService {
        DefaultRegistrationEventService(
            baseURL: baseURL,
            client: client,
            decoder: decoder,
            logger: logger
        )
    }
}

// MARK: - Private types

private struct NewToken: Decodable, Hashable {
    let token: String
    let expires: String
}
