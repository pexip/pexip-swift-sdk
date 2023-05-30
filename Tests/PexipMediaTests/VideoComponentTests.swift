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

import XCTest
@testable import PexipMedia

final class VideoComponentTests: XCTestCase {
    func testInitWithSetRenderer() {
        var expectedView: VideoRenderer?
        var expectedAspectFit: Bool?
        let contentMode = VideoContentMode.fit16x9
        let view = VideoRenderer()
        let component = VideoComponent(
            contentMode: contentMode,
            isMirrored: true,
            isReversed: true,
            setRenderer: { view, aspectFit in
                expectedView = view
                expectedAspectFit = aspectFit
            }
        )

        component.setRenderer(view, true)

        XCTAssertEqual(component.contentMode, contentMode)
        XCTAssertTrue(component.isMirrored)
        XCTAssertTrue(component.isReversed)
        XCTAssertTrue(expectedView === view)
        XCTAssertTrue(expectedAspectFit == true)
    }

    func testInitWithTrack() {
        let track = VideoTrackMock()
        let contentMode = VideoContentMode.fit16x9
        let view = VideoRenderer()
        let component = VideoComponent(
            track: track,
            contentMode: contentMode,
            isMirrored: true,
            isReversed: true
        )

        component.setRenderer(view, true)

        XCTAssertEqual(component.contentMode, contentMode)
        XCTAssertTrue(component.isMirrored)
        XCTAssertTrue(component.isReversed)
        XCTAssertTrue(track.view === view)
        XCTAssertTrue(track.aspectFit == true)
    }

    func testInitWithTrackAndDefaultValues() {
        let track = VideoTrackMock()
        let contentMode = VideoContentMode.fit16x9
        let view = VideoRenderer()
        let component = VideoComponent(
            track: track,
            contentMode: contentMode
        )

        component.setRenderer(view, true)

        XCTAssertEqual(component.contentMode, contentMode)
        XCTAssertFalse(component.isMirrored)
        XCTAssertFalse(component.isReversed)
        XCTAssertTrue(track.view === view)
        XCTAssertTrue(track.aspectFit == true)
    }

    func testInitWithVideo() {
        let track = VideoTrackMock()
        let contentMode = VideoContentMode.fit16x9
        let video = Video(track: track, contentMode: contentMode)
        let view = VideoRenderer()
        let component = VideoComponent(
            video: video,
            isMirrored: true,
            isReversed: true
        )

        component.setRenderer(view, false)

        XCTAssertEqual(component.contentMode, contentMode)
        XCTAssertTrue(component.isMirrored)
        XCTAssertTrue(component.isReversed)
        XCTAssertTrue(track.view === view)
        XCTAssertTrue(track.aspectFit == false)
    }

    func testInitWithVideoAndDefaultValues() {
        let track = VideoTrackMock()
        let contentMode = VideoContentMode.fit16x9
        let video = Video(track: track, contentMode: contentMode)
        let view = VideoRenderer()
        let component = VideoComponent(video: video)

        component.setRenderer(view, false)

        XCTAssertEqual(component.contentMode, contentMode)
        XCTAssertFalse(component.isMirrored)
        XCTAssertFalse(component.isReversed)
        XCTAssertTrue(track.view === view)
        XCTAssertTrue(track.aspectFit == false)
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

private final class VideoTrackMock: VideoTrack {
    var view: VideoRenderer?
    var aspectFit: Bool?

    func setRenderer(_ view: VideoRenderer, aspectFit: Bool) {
        self.view = view
        self.aspectFit = aspectFit
    }
}
