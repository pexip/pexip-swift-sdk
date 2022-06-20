import Foundation

struct MachAbsoluteTime {
    let value: UInt64

    init(_ value: UInt64) {
        self.value = value
    }

    var nanoseconds: UInt64 {
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        return value * UInt64(timebase.numer) / UInt64(timebase.denom)
    }
}
