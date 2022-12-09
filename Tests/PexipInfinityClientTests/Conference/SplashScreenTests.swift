import XCTest
import TestHelpers
@testable import PexipInfinityClient

final class SplashScreenTests: XCTestCase {
    private let layoutType = "direct_media"
    private let backgroundPath = "background.jpg"
    private let textType = "text"
    private let color = 4_294_967_295
    private let text1 = "Welcome"
    private let text2 = "Waiting for the host..."

    // MARK: - Tests

    func testInit() {
        let splashScreen = SplashScreen(
            layoutType: layoutType,
            background: .init(path: backgroundPath),
            elements: [
                .init(type: textType, color: color, text: text1),
                .init(type: textType, color: color, text: text2)
            ]
        )

        XCTAssertEqual(splashScreen.layoutType, layoutType)
        XCTAssertEqual(splashScreen.background.path, backgroundPath)
        XCTAssertEqual(splashScreen.elements.count, 2)

        XCTAssertEqual(splashScreen.elements.first?.type, textType)
        XCTAssertEqual(splashScreen.elements.first?.color, color)
        XCTAssertEqual(splashScreen.elements.first?.text, text1)

        XCTAssertEqual(splashScreen.elements.last?.type, textType)
        XCTAssertEqual(splashScreen.elements.last?.color, color)
        XCTAssertEqual(splashScreen.elements.last?.text, text2)
    }

    func testDecoding() throws {
        let json = """
        {
            "layout_type": "\(layoutType)",
            "background": {
                "path": "\(backgroundPath)"
            },
            "elements": [{
                "type": "\(textType)",
                "color": \(color),
                "text": "\(text1)"
            }]
        }
        """

        let data = try XCTUnwrap(json.data(using: .utf8))
        let splashScreen = try JSONDecoder().decode(
            SplashScreen.self,
            from: data
        )

        XCTAssertEqual(
            splashScreen,
            SplashScreen(
                layoutType: layoutType,
                background: .init(path: backgroundPath),
                elements: [
                    .init(type: textType, color: color, text: text1)
                ]
            )
        )
    }

    func testIsTextTypeElement() {
        let color = 4_294_967_295
        let element1 = SplashScreen.Element(
            type: "text",
            color: color,
            text: "Test"
        )
        let element2 = SplashScreen.Element(
            type: "not_text",
            color: color,
            text: "Test"
        )

        XCTAssertTrue(element1.isTextType)
        XCTAssertFalse(element2.isTextType)
    }
}
