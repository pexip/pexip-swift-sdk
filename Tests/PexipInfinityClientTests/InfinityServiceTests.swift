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

    func conference(alias: ConferenceAlias) -> ConferenceService {
        fatalError("Not implemented")
    }

    func registration(deviceAlias: DeviceAlias) -> RegistrationService {
        fatalError("Not implemented")
    }
}
