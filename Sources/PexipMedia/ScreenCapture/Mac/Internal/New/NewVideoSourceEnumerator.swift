#if os(macOS)

import CoreGraphics
#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

/**
 ScreenCaptureKit -based screen video source enumerator.
 https://developer.apple.com/documentation/screencapturekit
 */
@available(macOS 12.3, *)
struct NewScreenVideoSourceEnumerator: ScreenVideoSourceEnumerator {
    func getShareableDisplays() async throws -> [Display] {
        try await SCShareableContent
            .defaultSelection()
            .displays
            .map(Display.init(scDisplay:))
    }

    func getAllOnScreenWindows() async throws -> [Window] {
        try await SCShareableContent
            .defaultSelection()
            .windows
            .map(Window.init(scWindow:))
    }
}

#endif
