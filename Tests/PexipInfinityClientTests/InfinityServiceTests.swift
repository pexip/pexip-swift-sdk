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
}
