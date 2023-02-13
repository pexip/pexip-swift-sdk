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

/// A video processor that produces a new image
/// by manipulating the input video frame data.
public protocol VideoFilter {
    /**
     Produces a new image by manipulating the input video frame data.

     - Parameters:
        - pixelBuffer: The CVPixelBuffer containing the image to be processed.
        - orientation: A value describing the intended display orientation for an image.

     - Returns: The CVPixelBuffer containing the resulting image.
     */
    func processPixelBuffer(
        _ pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation
    ) -> CVPixelBuffer
}
