import XCTest
@testable import PexipMedia

final class VideoViewTests: XCTestCase {
    #if os(iOS)

    func testInit() {
        let view = VideoView(frame: .zero)
        XCTAssertEqual(view.backgroundColor, .black)
    }

    func testIsMirrored() {
        let view = VideoView(frame: .zero)
        XCTAssertEqual(view.transform, .identity)

        view.isMirrored = true
        XCTAssertEqual(view.transform, .init(scaleX: -1, y: 1))

        view.isMirrored = false
        XCTAssertEqual(view.transform, .identity)
    }

    #else

    func testInit() {
        let view = VideoView(frame: .zero)
        XCTAssertTrue(view.wantsLayer)
        XCTAssertEqual(view.layer?.backgroundColor, .black)
    }

    #endif
}
