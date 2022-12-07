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
