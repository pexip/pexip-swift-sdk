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
@testable import PexipInfinityClient

final class NodeServiceTests: APITestCase {
    private let baseURL = URL(string: "https://example.com")!
    private var service: NodeService!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        service = DefaultNodeService(baseURL: baseURL, client: client)
    }

    // MARK: - Tests

    /// In maintenance mode
    func testStatusWith503() async throws {
        try setResponse(statusCode: 503)
        let status = try await service.status()

        XCTAssertFalse(status)
        assertStatusRequest()
    }

    /// Not in maintenance mode
    func testStatusWith200() async throws {
        try setResponse(statusCode: 200)
        let status = try await service.status()

        XCTAssertTrue(status)
        assertStatusRequest()
    }

    func testStatusWith404() async throws {
        try setResponse(statusCode: 404)

        do {
            _ = try await service.status()
        } catch {
            XCTAssertEqual(error as? HTTPError, .resourceNotFound("Node"))
            assertStatusRequest()
        }
    }

    func testStatusWith401() async throws {
        try setResponse(statusCode: 401)

        do {
            _ = try await service.status()
        } catch {
            XCTAssertEqual(error as? HTTPError, .unacceptableStatusCode(401))
            assertStatusRequest()
        }
    }

    func testConference() throws {
        let alias = try XCTUnwrap(DeviceAlias(uri: "name@conference.com"))
        let service = service.conference(alias: alias) as? DefaultConferenceService

        XCTAssertEqual(
            service?.baseURL,
            baseURL
                .appendingPathComponent("conferences")
                .appendingPathComponent(alias.uri)
        )
    }

    func testRegistration() throws {
        let deviceAlias = try XCTUnwrap(DeviceAlias(uri: "device@conference.com"))
        let service = service.registration(
            deviceAlias: deviceAlias
        ) as? DefaultRegistrationService

        XCTAssertEqual(
            service?.baseURL,
            baseURL
                .appendingPathComponent("registrations")
                .appendingPathComponent(deviceAlias.uri)
        )
    }

    // MARK: - Test helpers

    private func assertStatusRequest() {
        assertRequest(
            withMethod: .GET,
            url: baseURL.appendingPathComponent("status"),
            data: nil
        )
    }
}
