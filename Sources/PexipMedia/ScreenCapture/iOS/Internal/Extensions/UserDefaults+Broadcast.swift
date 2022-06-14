#if os(iOS)

import Foundation

extension UserDefaults {
    private enum Key {
        static let broadcastFps = "com.pexip.PexipMedia.ScreenCapture.broadcastFps"
    }

    var broadcastFps: UInt? {
        get {
            UInt(integer(forKey: Key.broadcastFps))
        }
        set {
            if let newValue = newValue {
                setValue(Int(newValue), forKey: Key.broadcastFps)
            } else {
                removeObject(forKey: Key.broadcastFps)
            }
        }
    }
}

#endif
