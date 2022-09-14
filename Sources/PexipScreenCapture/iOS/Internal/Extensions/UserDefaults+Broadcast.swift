#if os(iOS)

import Foundation

extension UserDefaults {
    private enum Key {
        static let broadcastFps = "com.pexip.PexipMedia.ScreenCapture.broadcastFps"
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
}

#endif
