import XCTest
@testable import PexipMedia

final class VideoComponentTests: XCTestCase {
    func testInitWithTrack() {
        let track = VideoTrackMock()
        let contentMode = VideoContentMode.fit_16x9
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
        let contentMode = VideoContentMode.fit_16x9
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
        let contentMode = VideoContentMode.fit_16x9
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
        let contentMode = VideoContentMode.fit_16x9
        let video = Video(track: track, contentMode: contentMode)
        let component = VideoComponent(video: video)

        XCTAssertEqual(component.track as? VideoTrackMock, track)
        XCTAssertEqual(component.contentMode, contentMode)
        XCTAssertFalse(component.isMirrored)
        XCTAssertFalse(component.isReversed)
    }

    func testAspectRatio() {
        let track = VideoTrackMock()
        let contentMode = VideoContentMode.fit_16x9
        let component = VideoComponent(
            track: track,
            contentMode: contentMode
        )

        XCTAssertNotNil(component.aspectRatio)
        XCTAssertEqual(component.aspectRatio, contentMode.aspectRatio)
    }

    func testAspectRatioWhenRversed() {
        let track = VideoTrackMock()
        let contentMode = VideoContentMode.fit_16x9
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
