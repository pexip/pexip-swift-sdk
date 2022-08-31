import XCTest
import os.log
@testable import PexipCore

final class IsolatedTests: XCTestCase {
    func testInit() async {
        let object = Isolated("A")
        let value = await object.value

        XCTAssertEqual(value, "A")
    }

    func testSetValue() async {
        let object = Isolated("A")
        await object.setValue("B")
        let value = await object.value

        XCTAssertEqual(value, "B")
    }
}
