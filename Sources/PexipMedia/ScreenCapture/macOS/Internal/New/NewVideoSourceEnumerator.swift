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
struct NewScreenVideoSourceEnumerator<T: ShareableContent>: ScreenVideoSourceEnumerator {
    func getShareableDisplays() async throws -> [Display] {
        try await T.defaultSelection().displays
    }

    func getAllOnScreenWindows() async throws -> [Window] {
        try await T.defaultSelection().windows
    }
}

#endif
