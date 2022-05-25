#if os(macOS)

import Foundation
import CoreGraphics

/**
 Quartz Window Services -based video source enumerator.
 https://developer.apple.com/documentation/coregraphics/quartz_window_services
 */
struct LegacyScreenVideoSourceEnumerator: ScreenVideoSourceEnumerator {
    func getShareableDisplays() async throws -> [Display] {
        let displayCount = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
        var result = CGGetOnlineDisplayList(.max, nil, displayCount)

        guard result == .success else {
            throw ScreenCaptureError.cgError(result)
        }

        let displays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(
            capacity: Int(displayCount.pointee)
        )

        result = CGGetOnlineDisplayList(displayCount.pointee, displays, displayCount)

        guard result == .success else {
            throw ScreenCaptureError.cgError(result)
        }

        return Array(UnsafeBufferPointer(
            start: displays,
            count: Int(displayCount.pointee)
        )).compactMap {
            Display(displayID: $0)
        }
    }

    func getAllOnScreenWindows() async throws -> [Window] {
        let option: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]

        guard let windowInfoList = CGWindowListCopyWindowInfo(
            option,
            kCGNullWindowID
        ) else {
            return []
        }

        return (windowInfoList as [AnyObject]).compactMap { element -> Window? in
            guard let info = element as? [String: Any] else {
                return nil
            }
            return Window(info: info)
        }
    }
}

#endif
