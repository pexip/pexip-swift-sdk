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

import PexipScreenCapture

/// A local screen media track.
public protocol ScreenMediaTrack: LocalMediaTrack, VideoTrack {
    /**
     Starts the capture.

     - Parameters:
        - videoProfile: The video ``QualityProfile``
     */
    func startCapture(withVideoProfile videoProfile: QualityProfile) async throws

    /**
     Stops screen capture with the given reason.

     - Parameters:
        - reason: An optional reason why screen capture was stopped.
     */
    func stopCapture(reason: ScreenCaptureStopReason?)
}
