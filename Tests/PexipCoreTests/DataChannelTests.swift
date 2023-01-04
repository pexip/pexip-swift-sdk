import XCTest
@testable import PexipCore

final class DataChannelTests: XCTestCase {
    func testInit() {
        let id: Int32 = 11
        let dataChannel = DataChannel(id: id)
        XCTAssertEqual(dataChannel.id, id)
    }
}
