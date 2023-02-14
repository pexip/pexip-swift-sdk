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

import XCTest
@testable import PexipMedia

final class VideoTests: XCTestCase {
    func testInitWithTrackContentMode() {
        let track = VideoTrackMock()
        let contentMode = VideoContentMode.fit16x9
        let video = Video(track: track, contentMode: contentMode)

        XCTAssertEqual(video.track as? VideoTrackMock, track)
        XCTAssertEqual(video.contentMode, contentMode)
    }

    func testInitWithTrackQualityProfile() {
        let track = VideoTrackMock()
        let qualityProfile = QualityProfile.high
        let video = Video(track: track, qualityProfile: qualityProfile)

        XCTAssertEqual(video.track as? VideoTrackMock, track)
        XCTAssertEqual(video.contentMode, .fitQualityProfile(qualityProfile))
    }
}

// MARK: - Mocks

private struct VideoTrackMock: VideoTrack, Hashable {
    func setRenderer(_ view: VideoRenderer, aspectFit: Bool) {}
}
