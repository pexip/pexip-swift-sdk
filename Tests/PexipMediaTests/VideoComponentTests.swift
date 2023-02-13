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

final class VideoComponentTests: XCTestCase {
    func testInitWithTrack() {
        let track = VideoTrackMock()
        let contentMode = VideoContentMode.fit16x9
        let component = VideoComponent(
            track: track,
            contentMode: contentMode,
            isMirrored: true,
            isReversed: true
        )

        XCTAssertEqual(component.track as? VideoTrackMock, track)
        XCTAssertEqual(component.contentMode, contentMode)
        XCTAssertTrue(component.isMirrored)
        XCTAssertTrue(component.isReversed)
    }

    func testInitWithTrackAndDefaultValues() {
        let track = VideoTrackMock()
        let contentMode = VideoContentMode.fit16x9
        let component = VideoComponent(
            track: track,
            contentMode: contentMode
        )

        XCTAssertEqual(component.track as? VideoTrackMock, track)
        XCTAssertEqual(component.contentMode, contentMode)
        XCTAssertFalse(component.isMirrored)
        XCTAssertFalse(component.isReversed)
    }

    func testInitWithVideo() {
        let track = VideoTrackMock()
        let contentMode = VideoContentMode.fit16x9
        let video = Video(track: track, contentMode: contentMode)
        let component = VideoComponent(
            video: video,
            isMirrored: true,
            isReversed: true
        )

        XCTAssertEqual(component.track as? VideoTrackMock, track)
        XCTAssertEqual(component.contentMode, contentMode)
        XCTAssertTrue(component.isMirrored)
        XCTAssertTrue(component.isReversed)
    }

    func testInitWithVideoAndDefaultValues() {
        let track = VideoTrackMock()
        let contentMode = VideoContentMode.fit16x9
        let video = Video(track: track, contentMode: contentMode)
        let component = VideoComponent(video: video)

        XCTAssertEqual(component.track as? VideoTrackMock, track)
        XCTAssertEqual(component.contentMode, contentMode)
        XCTAssertFalse(component.isMirrored)
        XCTAssertFalse(component.isReversed)
    }

    func testAspectRatio() {
        let track = VideoTrackMock()
        let contentMode = VideoContentMode.fit16x9
        let component = VideoComponent(
            track: track,
            contentMode: contentMode
        )

        XCTAssertNotNil(component.aspectRatio)
        XCTAssertEqual(component.aspectRatio, contentMode.aspectRatio)
    }

    func testAspectRatioWhenRversed() {
        let track = VideoTrackMock()
        let contentMode = VideoContentMode.fit16x9
        let component = VideoComponent(
            track: track,
            contentMode: contentMode,
            isReversed: true
        )

        XCTAssertNotNil(component.aspectRatio)
        XCTAssertEqual(component.aspectRatio, CGSize(width: 9, height: 16))
    }
}

// MARK: - Mocks

private struct VideoTrackMock: VideoTrack, Hashable {
    func setRenderer(_ view: VideoRenderer, aspectFit: Bool) {}
}
