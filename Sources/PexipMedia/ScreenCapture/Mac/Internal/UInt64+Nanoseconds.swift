import Foundation

extension UInt64 {
    var nanoseconds: UInt64 {
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        return self * UInt64(timebase.numer) / UInt64(timebase.denom)
    }
}
