import XCTest
@testable import PexipInfinityClient

final class InfinityServiceTests: XCTestCase {
    private let baseURL = URL(string: "https://example.com")!
    private var service: InfinityService!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolMock.self]

        service = DefaultInfinityService(
            client: HTTPClient(session: URLSession(configuration: configuration))
        )
    }

    // MARK: - Tests

    func testNodeServiceBaseURL() {
        let url = URL(string: "https://vc.example.com")!
        let nodeService = service.node(url: url)
        XCTAssertEqual(nodeService.baseURL, url.appendingPathComponent("api/client/v2"))
    }
}
