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

import CoreVideo
import CoreImage
import PexipMedia
import PexipVideoFilters

enum CameraVideoFilter: String, CaseIterable {
    case gaussianBlur = "Gaussian Blur"
    case tentBlur = "Tent Blur"
    case boxBlur = "Box Blur"
    case imageBackground = "Image Background"
}

extension VideoFilterFactory {
    func videoFilter(for filter: CameraVideoFilter?) -> VideoFilter? {
        switch filter {
        case .none:
            return nil
        case .gaussianBlur:
            return segmentation(background: .gaussianBlur(radius: 30))
        case .tentBlur:
            return segmentation(background: .tentBlur(intensity: 0.3))
        case .boxBlur:
            return segmentation(background: .boxBlur(intensity: 0.3))
        case .imageBackground:
            if let image = CGImage.withName("background_image") {
                return segmentation(background: .image(image))
            } else {
                return nil
            }
        }
    }
}
