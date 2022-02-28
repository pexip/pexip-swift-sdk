import XCTest
@testable import PexipVideo

final class NodeTests: XCTestCase {
    func testInit() {
        let url = URL(string: "https://example.com")!
        let node = Node(address: url)
        XCTAssertEqual(node.address, url)
    }
}
