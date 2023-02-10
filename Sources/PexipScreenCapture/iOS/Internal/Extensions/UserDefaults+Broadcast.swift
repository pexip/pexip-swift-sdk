#if os(iOS)

import Foundation

extension UserDefaults {
    private enum Key {
        static let broadcastFps = "com.pexip.PexipScreenCapture.broadcastFps"
        static let broadcastKeepAliveDate = "com.pexip.PexipScreenCapture.broadcastKeepAliveDate"
    }

    var broadcastFps: UInt? {
        get {
            let value = UInt(integer(forKey: Key.broadcastFps))
            return value > 0 ? value : nil
        }
        set {
            if let newValue {
                setValue(Int(newValue), forKey: Key.broadcastFps)
            } else {
                removeObject(forKey: Key.broadcastFps)
            }
        }
    }

    var broadcastKeepAliveDate: Date? {
        get { object(forKey: Key.broadcastKeepAliveDate) as? Date }
        set {
            if let newValue {
                setValue(newValue, forKey: Key.broadcastKeepAliveDate)
            } else {
                removeObject(forKey: Key.broadcastKeepAliveDate)
            }
        }
    }
}

#endif
