#if os(macOS)

#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

@available(macOS 12.3, *)
extension SCShareableContent {
    static func defaultSelection() async throws -> SCShareableContent {
        try await SCShareableContent.excludingDesktopWindows(
            true,
            onScreenWindowsOnly: true
        )
    }
}

#endif
