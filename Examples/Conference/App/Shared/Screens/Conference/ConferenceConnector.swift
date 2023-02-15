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

import SwiftUI
import PexipInfinityClient

final class ConferenceConnector {
    enum RequestMethod {
        case pin(String?)
        case incomingToken(String)
    }

    private let nodeResolver: NodeResolver
    private let service: InfinityService

    // MARK: - Init

    init(
        nodeResolver: NodeResolver,
        service: InfinityService
    ) {
        self.nodeResolver = nodeResolver
        self.service = service
    }

    // MARK: - Internal

    func join(
        using method: RequestMethod,
        displayName: String,
        conferenceAlias: String
    ) async throws -> ConferenceDetails {
        guard let alias = ConferenceAlias(uri: conferenceAlias) else {
            throw NodeError.invalidConferenceAlias
        }

        let node = try await resolveNode(forHost: alias.host)
        let conferenceService = service.node(url: node).conference(alias: alias)
        let fields = ConferenceTokenRequestFields(displayName: displayName)
        let token: ConferenceToken

        switch method {
        case .pin(let pin):
            token = try await conferenceService.requestToken(
                fields: fields,
                pin: pin
            )
        case .incomingToken(let value):
            token = try await conferenceService.requestToken(
                fields: fields,
                incomingToken: value
            )
        }

        return ConferenceDetails(node: node, alias: alias, token: token)
    }

    // MARK: - Private

    private func resolveNode(forHost host: String) async throws -> URL {
        if let node = try await service.resolveNodeURL(
            forHost: host,
            using: nodeResolver
        ) {
            return node
        }

        throw NodeError.nodeNotFound
    }
}

// MARK: - Errors

enum NodeError: LocalizedError {
    case invalidConferenceAlias
    case nodeNotFound

    var errorDescription: String? {
        switch self {
        case .invalidConferenceAlias:
            return "Looks like the address doesn't exist"
        case .nodeNotFound:
            return "Conferencing node not found"
        }
    }
}
