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

/// A helper type that groups the video track with its content mode.
public struct Video {
    /// The video track.
    public let track: VideoTrack
    /// The content mode of the video.
    public let contentMode: VideoContentMode

    /**
     Creates a new instance of ``Video``.
     - Parameters:
        - track: The video track
        - contentMode: Indicates whether the view should fit or fill the parent context
     */
    public init(track: VideoTrack, contentMode: VideoContentMode) {
        self.track = track
        self.contentMode = contentMode
    }

    /**
     Creates a new instance of ``Video``.
     - Parameters:
        - track: The video track
        - qualityProfile: The quality profile of the video
     */
    public init(track: VideoTrack, qualityProfile: QualityProfile) {
        self.init(track: track, contentMode: .fitQualityProfile(qualityProfile))
    }
}
