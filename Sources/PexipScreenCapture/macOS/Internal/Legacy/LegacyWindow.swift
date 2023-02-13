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
