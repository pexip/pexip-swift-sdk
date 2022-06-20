import XCTest
import AVFoundation
@testable import PexipMedia

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
}

// MARK: - Mocks

private struct VideoTrackMock: VideoTrack, Hashable {
    func setRenderer(_ view: VideoRenderer, aspectFit: Bool) {}
}
