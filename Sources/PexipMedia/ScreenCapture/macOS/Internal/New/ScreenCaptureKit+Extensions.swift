#if os(macOS)

#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

/**
 All the protocols and extensions below
 are needed to enable mocking in unit tests.
 */

// MARK: - ShareableContent

@available(macOS 12.3, *)
protocol ShareableContent {
    associatedtype Content: ShareableContent
    associatedtype D: Display
    associatedtype W: Window

    static func excludingDesktopWindows(
        _ excludeDesktopWindows: Bool,
        onScreenWindowsOnly: Bool
    ) async throws -> Content

    var displays: [D] { get }
    var windows: [W] { get }
}

@available(macOS 12.3, *)
extension ShareableContent {
    static func defaultSelection() async throws -> Content {
        try await Self.excludingDesktopWindows(
            true,
            onScreenWindowsOnly: true
        )
    }
}

@available(macOS 12.3, *)
extension SCShareableContent: ShareableContent {}

// MARK: - ContentFilter

protocol ScreenCaptureContentFilter {
    associatedtype D: Display
    associatedtype W: Window

    init(desktopIndependentWindow window: W)
    init(display: D, excludingWindows excluded: [W])
}

@available(macOS 12.3, *)
extension SCContentFilter: ScreenCaptureContentFilter {}

// MARK: - Window

@available(macOS 12.3, *)
extension SCWindow: Window {
    public var application: RunningApplication? {
        return owningApplication
    }
}

// MARK: - Display

@available(macOS 12.3, *)
extension SCDisplay: Display {}

// MARK: - RunningApplication

@available(macOS 12.3, *)
extension SCRunningApplication: RunningApplication {}

#endif
