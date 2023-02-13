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

import CoreGraphics

/// An object that represents an onscreen window.
public protocol Window: ScreenVideoContent {
    /// The Core Graphics window identifier.
    var windowID: CGWindowID { get }
    /// The string that displays in a window’s title bar.
    var title: String? { get }
    /// The app that owns the window.
    var application: RunningApplication? { get }
    /// The CGRect for the window
    var frame: CGRect { get }
    /// A Boolean value that indicates whether the window is on screen.
    var isOnScreen: Bool { get }
    /// The window layer of the window.
    var windowLayer: Int { get }
}

// MARK: - Default implementations

public extension Window {
    /// The width of the window in points.
    var width: Int {
        Int(frame.size.width)
    }

    /// The height of the window in points.
    var height: Int {
        Int(frame.size.height)
    }

    /// Returns an image containing the contents of the window.
    func createImage() -> CGImage? {
        CGWindowListCreateImage(
            .null,
            .optionIncludingWindow, windowID,
            [.boundsIgnoreFraming, .nominalResolution]
        )
    }
}

#endif
