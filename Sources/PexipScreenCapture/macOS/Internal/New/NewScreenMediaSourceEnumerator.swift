#if os(macOS)

import CoreGraphics
#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

/**
 ScreenCaptureKit -based screen media source enumerator.
 https://developer.apple.com/documentation/screencapturekit
 */
@available(macOS 12.3, *)
struct NewScreenMediaSourceEnumerator<T: ShareableContent>: ScreenMediaSourceEnumerator {
    func getShareableDisplays() async throws -> [Display] {
        try await T.defaultSelection().displays
    }

    func getAllOnScreenWindows() async throws -> [Window] {
        try await T.defaultSelection().windows
    }
}

#endif
