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

enum Settings {
    enum Filter: String, CaseIterable, Hashable {
        case noFilters = "None"
        case gaussianBlur = "Gaussian Blur"
        case tentBlur = "Tent Blur"
        case boxBlur = "Box Blur"
        case imageBackground = "Image Background"
        case videoBackground = "Video Background"
        case sepiaTone = "Sepia Tone"
        case blackAndWhite = "Black And White"
        case instantStyle = "Instant Style Effect"
        case instantStyleWithGaussianBlur = "Instant Style + Gaussian Blur"
    }

    enum Segmentation: String, CaseIterable, Hashable {
        case vision = "Vision"
        case googleMLKit = "Google ML Kit"
    }
}
