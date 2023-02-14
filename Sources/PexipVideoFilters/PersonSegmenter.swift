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

/// An object that detects and generates an image mask for a person in an image.
public protocol PersonSegmenter {
    /**
     Detects and generates an image mask for a person in the given pixel buffer.

     - Parameters:
        - pixelBuffer: The CVPixelBuffer containing the image to be processed.
     - Returns: The CVPixelBuffer containing the resulting image mask.
     */
    func personMaskPixelBuffer(from pixelBuffer: CVPixelBuffer) -> CVPixelBuffer?
}
