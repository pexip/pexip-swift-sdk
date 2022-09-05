import XCTest
@testable import PexipCore

final class SynchronizedTests: XCTestCase {
    func testValue() {
        let number = Synchronized(0)
        XCTAssertEqual(number.value, 0)
    }

    func testSetValue() {
        let number = Synchronized(0)
        number.setValue(1)
        XCTAssertEqual(number.value, 1)
    }

    func testMutate() {
        let number = Synchronized(0)
        number.setValue(1)
        number.mutate {
            $0 += 1
        }
        XCTAssertEqual(number.value, 2)
    }
}
