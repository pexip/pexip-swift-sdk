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
import AVFoundation
@testable import PexipMedia

@MainActor
final class RemoteVideoTracksTests: XCTestCase {
    func testInit() {
        let mainTrack = VideoTrackMock()
        let presentationTrack = VideoTrackMock()

        let tracks = RemoteVideoTracks(
            mainTrack: mainTrack,
            presentationTrack: presentationTrack
        )

        XCTAssertEqual(tracks.mainTrack as? VideoTrackMock, mainTrack)
        XCTAssertEqual(tracks.presentationTrack as? VideoTrackMock, presentationTrack)
    }

    func testSetMainTrack() async {
        let track = VideoTrackMock()
        let tracks = RemoteVideoTracks(
            mainTrack: nil,
            presentationTrack: nil
        )

        tracks.setMainTrack(track)

        await Task { @MainActor in
            XCTAssertEqual(tracks.mainTrack as? VideoTrackMock, track)
        }.value
    }

    func testSetPresentationTrack() async {
        let track = VideoTrackMock()
        let tracks = RemoteVideoTracks(
            mainTrack: nil,
            presentationTrack: nil
        )

        tracks.setPresentationTrack(track)

        await Task { @MainActor in
            XCTAssertEqual(tracks.presentationTrack as? VideoTrackMock, track)
        }.value
    }
}

// MARK: - Mocks

private struct VideoTrackMock: VideoTrack, Hashable {
    let id = UUID()
    func setRenderer(_ view: VideoRenderer, aspectFit: Bool) {}
}
