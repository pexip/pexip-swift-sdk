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
import CoreMedia

/// An object that represents a screen video content your app can capture.
public protocol ScreenVideoContent {
    /// The width of the screen content in points.
    var width: Int { get }

    /// The height of the screen content in points.
    var height: Int { get }

    /// Returns an image containing the captured content of the screen.
    func createImage() -> CGImage?
}

// MARK: - Default implementations

public extension ScreenVideoContent {
    /// The aspect ratio of the screen content.
    var aspectRatio: CGFloat {
        CGFloat(width) / CGFloat(height)
    }

    /// The video dimensions on the sceen content.
    var videoDimensions: CMVideoDimensions {
        CMVideoDimensions(
            width: Int32(width),
            height: Int32(height)
        )
    }
}

#endif
