#if os(macOS)

import Foundation
import CoreGraphics
import AppKit

/**
 Quartz Window Services -based video source enumerator.
 https://developer.apple.com/documentation/coregraphics/quartz_window_services
 */
struct LegacyScreenVideoSourceEnumerator: ScreenVideoSourceEnumerator {
    var getOnlineDisplayList = CGGetOnlineDisplayList
    var getWindowInfoList = CGWindowListCopyWindowInfo
    var displayMode: (CGDirectDisplayID) -> DisplayMode? = {
        CGDisplayCopyDisplayMode($0)
    }
    var workspace: NSWorkspace = .shared

    // MARK: - ScreenVideoSourceEnumerator

    func getShareableDisplays() async throws -> [Display] {
        let displayCount = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
        var result = getOnlineDisplayList(.max, nil, displayCount)

        guard result == .success else {
            throw ScreenCaptureError.cgError(result)
        }

        let displays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(
            capacity: Int(displayCount.pointee)
        )

        result = getOnlineDisplayList(
            displayCount.pointee,
            displays, displayCount
        )

        guard result == .success else {
            throw ScreenCaptureError.cgError(result)
        }

        return Array(UnsafeBufferPointer(
            start: displays,
            count: Int(displayCount.pointee)
        )).compactMap {
            LegacyDisplay(displayID: $0, displayMode: displayMode)
        }
    }

    func getAllOnScreenWindows() async throws -> [Window] {
        let option: CGWindowListOption = [
            .optionOnScreenOnly,
            .excludeDesktopElements
        ]

        guard let windowInfoList = getWindowInfoList(
            option,
            kCGNullWindowID
        ) else {
            return []
        }

        return (windowInfoList as [AnyObject]).compactMap { element -> Window? in
            guard let info = element as? [CFString: Any] else {
                return nil
            }

            return LegacyWindow(info: info, workspace: workspace)
        }
    }
}

#endif
