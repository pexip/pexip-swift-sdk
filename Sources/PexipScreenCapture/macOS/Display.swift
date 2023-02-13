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

/// An object that represents a display device.
public protocol Display: ScreenVideoContent {
    /// The Core Graphics display identifier.
    var displayID: CGDirectDisplayID { get }

    /// The width of the display in points.
    var width: Int { get }

    /// The height of the display in points.
    var height: Int { get }
}

// MARK: - Default implementations

public extension Display {
    /// Returns an image containing the contents of the display.
    func createImage() -> CGImage? {
        CGDisplayCreateImage(displayID)
    }
}

#endif
