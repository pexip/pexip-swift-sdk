//
// Copyright 2022-2023 Pexip AS
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

// MARK: - Protocol

/// A fluent client for Infinity REST API v2.
public protocol InfinityService {
    /**
     Creates a new ``NodeService``.
     - Parameters:
        - url: A conferencing node address in the form of https://example.com
     - Returns: A new instance of ``NodeService``
     */
    func node(url: URL) -> NodeService
}

public extension InfinityService {
    /// Resolves the first available conferencing node.
    /// 
    /// - Parameters:
    ///   - host: A host to use to resolve the best node address.
    ///   - nodeResolver: An instance of ``NodeResolver``
    /// - Returns: A conferencing node address
    func resolveNodeURL(
        forHost host: String,
        using nodeResolver: NodeResolver
    ) async throws -> URL? {
        for url in try await nodeResolver.resolveNodes(for: host) {
            try Task.checkCancellation()
            if try await node(url: url).status() {
                return url
            }
        }

        return nil
    }
}

// MARK: - Implementation

struct DefaultInfinityService: InfinityService {
    let client: HTTPClient
    var decoder = JSONDecoder()
    var logger: Logger?

    func node(url: URL) -> NodeService {
        let url = url.appendingPathComponent("api/client/v2")
        return DefaultNodeService(
            baseURL: url,
            client: client,
            decoder: decoder,
            logger: logger
        )
    }
}
