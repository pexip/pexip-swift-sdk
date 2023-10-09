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

// swiftlint:disable line_length

// MARK: - Protocol

/// Represents the [Other miscellaneous requests](https://docs.pexip.com/api_client/api_rest.htm?Highlight=api#misc) section.
public protocol NodeService {
    /// The base url.
    var baseURL: URL { get }

    /**
     Checks the status of the conferencing node.

     - Parameters:
       - nodeAddress: a node address in the form of https://example.com

     - Returns: False if the node is in maintenance mode, true if the node is available
     - Throws: `NodeError.nodeNotFound` if supplied `nodeAddress` doesn't have a deployment
     - Throws: `HTTPError.unacceptableStatusCode` if the response wasn't handled by the client
     - Throws: `Error` if another type of error was encountered during operation
     */
    func status() async throws -> Bool

    /**
     Sets the conference alias.

     - Parameters:
        - alias: A conference alias
     - Returns: A conference service for the given alias.
     */
    func conference(alias: String) -> ConferenceService

    /**
     Sets the registration alias.

     - Parameters:
        - alias: A device alias
     - Returns: A registration service for the given alias.
     */
    func registration(deviceAlias: String) -> RegistrationService
}

// MARK: - Implementation

struct DefaultNodeService: NodeService {
    let baseURL: URL
    let client: HTTPClient
    var decoder = JSONDecoder()
    var logger: Logger?

    func status() async throws -> Bool {
        let request = URLRequest(
            url: baseURL.appendingPathComponent("status"),
            httpMethod: .GET
        )
        let (_, response) = try await client.data(for: request, validate: false)

        switch response.statusCode {
        case 200:
            return true
        case 404:
            throw HTTPError.resourceNotFound("Node")
        case 503:
            return false
        default:
            throw HTTPError.unacceptableStatusCode(response.statusCode)
        }
    }

    func conference(alias: ConferenceAddress) -> ConferenceService {
        conference(alias: alias.alias)
    }

    func conference(alias: String) -> ConferenceService {
        DefaultConferenceService(
            baseURL: baseURL
                .appendingPathComponent("conferences")
                .appendingPathComponent(alias),
            client: client,
            decoder: decoder,
            logger: logger
        )
    }

    func registration(deviceAlias: DeviceAddress) -> RegistrationService {
        registration(deviceAlias: deviceAlias.alias)
    }

    func registration(deviceAlias: String) -> RegistrationService {
        DefaultRegistrationService(
            baseURL: baseURL
                .appendingPathComponent("registrations")
                .appendingPathComponent(deviceAlias),
            client: client,
            decoder: decoder,
            logger: logger
        )
    }
}
// swiftlint:enable line_length
