import XCTest
@testable import PexipVideo

final class SequenceAsyncTests: XCTestCase {
    func testAsyncFirst() async {
        var index = 0

        func number() async -> Int {
            index += 1
            return index
        }

        let value = await Array(0..<10).asyncFirst(where: { $0 == 7 })
        XCTAssertEqual(value, 7)
    }
}
