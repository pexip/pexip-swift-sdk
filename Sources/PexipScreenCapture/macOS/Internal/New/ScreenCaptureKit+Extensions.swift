#if os(macOS)

#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

// All the protocols and extensions below
// are needed to enable mocking in unit tests.

// MARK: - ShareableContent

// swiftlint:disable type_name
@available(macOS 12.3, *)
protocol ShareableContent {
    associatedtype Content: ShareableContent
    associatedtype D: Display
    associatedtype W: Window
    associatedtype A: RunningApplication

    static func excludingDesktopWindows(
        _ excludeDesktopWindows: Bool,
        onScreenWindowsOnly: Bool
    ) async throws -> Content

    var displays: [D] { get }
    var windows: [W] { get }
    var applications: [A] { get }
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
    associatedtype A: RunningApplication

    init(desktopIndependentWindow window: W)
    init(
        display: D,
        excludingApplications applications: [A],
        exceptingWindows: [W]
    )
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
