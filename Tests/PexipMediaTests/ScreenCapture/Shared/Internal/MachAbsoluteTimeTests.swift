import XCTest
@testable import PexipMedia

final class MachAbsoluteTimeTests: XCTestCase {
    func testNanoseconds() {
        let value: UInt64 = 10000
        let time = MachAbsoluteTime(value)
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        let nanoseconds = value * UInt64(timebase.numer) / UInt64(timebase.denom)

        XCTAssertEqual(time.value, value)
        XCTAssertEqual(time.nanoseconds, nanoseconds)
    }
}
