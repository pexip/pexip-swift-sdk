//
// Copyright 2022 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#if os(macOS)

import Foundation
import CoreGraphics
import AppKit

/**
 Quartz Window Services -based screen media source enumerator.
 https://developer.apple.com/documentation/coregraphics/quartz_window_services
 */
struct LegacyScreenMediaSourceEnumerator: ScreenMediaSourceEnumerator {
    var getOnlineDisplayList = CGGetOnlineDisplayList
    var getWindowInfoList = CGWindowListCopyWindowInfo
    var displayMode: (CGDirectDisplayID) -> DisplayMode? = {
        CGDisplayCopyDisplayMode($0)
    }
    var workspace: NSWorkspace = .shared

    // MARK: - ScreenMediaSourceEnumerator

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
            displays,
            displayCount
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
