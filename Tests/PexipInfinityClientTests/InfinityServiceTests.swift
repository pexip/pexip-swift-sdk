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

import XCTest
@testable import PexipInfinityClient

final class InfinityServiceTests: APITestCase {
    private let baseURL = URL(string: "https://example.com")!
    private var service: InfinityService!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        service = DefaultInfinityService(client: client)
    }

    // MARK: - Tests

    func testNodeServiceBaseURL() {
        let url = URL(string: "https://vc.example.com")!
        let nodeService = service.node(url: url)
        XCTAssertEqual(nodeService.baseURL, url.appendingPathComponent("api/client/v2"))
    }

    func testResolveNodeURLWhenAvailable() async throws {
        let nodes = [
            URL(string: "https://vc1.example.com")!,
            URL(string: "https://vc2.example.com")!,
            URL(string: "https://vc3.example.com")!
        ]
        let nodeResolver = NodeResolverMock(nodes: nodes)
        let service = InfinityServiceMock(statuses: [
            nodes[0]: false,
            nodes[1]: true,
            nodes[2]: true
        ])
        let node = try await service.resolveNodeURL(
            forHost: "example.com",
            using: nodeResolver
        )

        XCTAssertEqual(node, nodes[1])
    }

    func testResolveNodeURLWhenNotAvailable() async throws {
        let nodes = [
            URL(string: "https://vc1.example.com")!,
            URL(string: "https://vc2.example.com")!
        ]
        let nodeResolver = NodeResolverMock(nodes: nodes)
        let service = InfinityServiceMock(statuses: [
            nodes[0]: false,
            nodes[1]: false
        ])
        let node = try await service.resolveNodeURL(
            forHost: "example.com",
            using: nodeResolver
        )

        XCTAssertNil(node)
    }
}

// MARK: - Mocks

private struct NodeResolverMock: NodeResolver {
    let nodes: [URL]

    func resolveNodes(for host: String) async throws -> [URL] {
        nodes
    }
}

private struct InfinityServiceMock: InfinityService {
    var statuses = [URL: Bool]()

    func node(url: URL) -> NodeService {
        NodeServiceMock(baseURL: url, status: statuses[url] ?? false)
    }
}

// swiftlint:disable unavailable_function
private struct NodeServiceMock: NodeService {
    let baseURL: URL
    let status: Bool

    func status() async throws -> Bool {
        status
    }

    func conference(alias: ConferenceAddress) -> ConferenceService {
        fatalError("Not implemented")
    }

    func conference(alias: String) -> PexipInfinityClient.ConferenceService {
        fatalError("Not implemented")
    }

    func registration(deviceAlias: DeviceAddress) -> RegistrationService {
        fatalError("Not implemented")
    }

    func registration(deviceAlias: String) -> PexipInfinityClient.RegistrationService {
        fatalError("Not implemented")
    }
}
// swiftlint:enable unavailable_function
