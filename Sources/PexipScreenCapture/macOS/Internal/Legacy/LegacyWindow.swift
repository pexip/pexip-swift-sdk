#if os(macOS)

import AppKit
import CoreGraphics

struct LegacyWindow: Window {
    let windowID: CGWindowID
    let title: String?
    let application: RunningApplication?
    let frame: CGRect
    let isOnScreen: Bool
    let windowLayer: Int
}

// MARK: - Init

extension LegacyWindow {
    init?(info: [CFString: Any], workspace: NSWorkspace = .shared) {
        guard let windowID = info[kCGWindowNumber] as? Int else {
            return nil
        }

        guard let rect = info[kCGWindowBounds] as? NSDictionary,
              let bounds = CGRect(dictionaryRepresentation: rect)
        else {
            return nil
        }

        guard let isOnScreen = info[kCGWindowIsOnscreen] as? Bool else {
            return nil
        }

        guard let windowLayer = info[kCGWindowLayer] as? Int else {
            return nil
        }

        self.windowID = CGWindowID(windowID)
        self.title = info[kCGWindowName] as? String
        self.application = LegacyRunningApplication(
            info: info,
            workspace: workspace
        )
        self.frame = bounds
        self.windowLayer = windowLayer
        self.isOnScreen = isOnScreen
    }
}

#endif
