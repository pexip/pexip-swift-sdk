//
// Copyright 2022-2023 Pexip AS
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

import CoreGraphics

/// Indicates whether the video view should fit or fill the parent context
@frozen
public enum VideoContentMode: Equatable {
    /// Fit the size of the view by maintaining the aspect ratio (9:16)
    case fit16x9
    /// Fit the size of the view by maintaining the aspect ratio (4:3)
    case fit4x3
    /// Fit the size of the view by maintaining the given aspect ratio
    case fitAspectRatio(CGSize)
    /// Fit the size of the view by maintaining the aspect ratio
    /// from quality profile
    case fitQualityProfile(QualityProfile)
    /// Fill the parent context
    case fill
    /// Fit the size of the view by maintaining the original aspect ratio of the video
    case fit

    public var aspectRatio: CGSize? {
        switch self {
        case .fit16x9:
            return CGSize(width: 16, height: 9)
        case .fit4x3:
            return CGSize(width: 4, height: 3)
        case .fitAspectRatio(let size):
            return size
        case .fitQualityProfile(let qualityProfile):
            return qualityProfile.aspectRatio
        case .fill, .fit:
            return nil
        }
    }
}
