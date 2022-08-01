import XCTest
@testable import PexipInfinityClient

final class DTMFSignalsTests: XCTestCase {
    func testInitWithValidRawValue() {
        XCTAssertEqual(DTMFSignals(rawValue: " 01234 ")?.rawValue, "01234")

        do {
            let value = "0123456789*#ABCD"
            XCTAssertEqual(DTMFSignals(rawValue: value)?.rawValue, value)
        }

        do {
            let value = "01234AB"
            XCTAssertEqual(DTMFSignals(rawValue: value)?.rawValue, value)
        }

        do {
            let value = "#ABCD"
            XCTAssertEqual(DTMFSignals(rawValue: value)?.rawValue, value)
        }

        do {
            let value = "*"
            XCTAssertEqual(DTMFSignals(rawValue: value)?.rawValue, value)
        }
    }

    func testInitWithInvalidRawValue() {
        XCTAssertNil(DTMFSignals(rawValue: ""))
        XCTAssertNil(DTMFSignals(rawValue: "01234T"))
        XCTAssertNil(DTMFSignals(rawValue: "Test"))
    }
}
