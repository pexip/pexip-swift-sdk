import XCTest
@testable import PexipVideo

final class CallKindTests: XCTestCase {
    func testIsPresentation() {
        XCTAssertFalse(
            CallKind.call(presentationInMix: true).isPresentation
        )
        XCTAssertFalse(
            CallKind.call(presentationInMix: false).isPresentation
        )
        XCTAssertTrue(CallKind.presentationReceiver.isPresentation)
        XCTAssertTrue(CallKind.presentationSender.isPresentation)
    }
}
