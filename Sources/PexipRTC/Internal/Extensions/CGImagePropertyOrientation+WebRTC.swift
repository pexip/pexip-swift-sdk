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

import ImageIO
import WebRTC

extension CGImagePropertyOrientation {
    var rtcRotation: RTCVideoRotation {
        switch self {
        case .up, .upMirrored, .down, .downMirrored:
            return ._0
        case .left, .leftMirrored:
            return ._90
        case .right, .rightMirrored:
            return ._270
        default:
            return ._0
        }
    }

    init(rtcRotation: RTCVideoRotation) {
        switch rtcRotation {
        case ._0:
            self = .up
        case ._90:
            self = .left
        case ._270:
            self = .right
        case ._180:
            self = .down
        @unknown default:
            self = .up
        }
    }
}
