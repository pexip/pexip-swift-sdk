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
