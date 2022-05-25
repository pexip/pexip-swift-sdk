#if os(macOS)

import CoreGraphics
#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

/// An object that represents an onscreen window.
public struct Window: Hashable {
    /// The Core Graphics window identifier.
    public let windowID: CGWindowID
    /// The string that displays in a window’s title bar.
    public let title: String?
    /// The app that owns the window.
    public let owningApplication: RunningApplication?
    /// The width of the window in points.
    public let width: Int
    /// The height of the window in points.
    public let height: Int
    /// A Boolean value that indicates whether the window is on screen.
    public let isOnScreen: Bool
    /// The window layer.
    public let windowLayer: Int
    /// Optional preview image, use ``createImage()`` to create a new one.
    public let previewImage: CGImage?
    /// The aspect ration of the window.
    public var aspectRatio: CGFloat {
        CGFloat(width) / CGFloat(height)
    }

    /// Returns an image containing the contents of the window.
    public func createImage() -> CGImage? {
        CGWindowListCreateImage(
            .null,
            .optionIncludingWindow, windowID,
            [.boundsIgnoreFraming, .nominalResolution]
        )
    }

    // MARK: - Init

    /**
     Creates a new object that represents an onscreen window.
     - Parameters:
        - windowID: The Core Graphics window identifier.
        - title: The string that displays in a window’s title bar.
        - owningApplication: The app that owns the window.
        - width: The width of the window in points.
        - height: The height of the window in points.
        - isOnScreen: A Boolean value that indicates whether the window is on screen.
        - windowLayer: The window layer.
        - previewImage: Optional preview image, use ``createImage()`` to create a new one.
     */
    public init(
        windowID: CGWindowID,
        title: String?,
        owningApplication: RunningApplication?,
        width: Int,
        height: Int,
        isOnScreen: Bool,
        windowLayer: Int = 0,
        previewImage: CGImage? = nil
    ) {
        self.windowID = windowID
        self.title = title
        self.owningApplication = owningApplication
        self.width = width
        self.height = height
        self.isOnScreen = isOnScreen
        self.windowLayer = windowLayer
        self.previewImage = previewImage
    }

    @available(macOS 12.3, *)
    init(scWindow: SCWindow) {
        self.windowID = scWindow.windowID
        self.title = scWindow.title
        self.owningApplication = scWindow.owningApplication.map {
            RunningApplication(scRunningApplication: $0)
        }
        self.width = Int(scWindow.frame.size.width)
        self.height = Int(scWindow.frame.size.height)
        self.isOnScreen = scWindow.isOnScreen
        self.windowLayer = scWindow.windowLayer
        self.previewImage = nil
    }

    init?(info: [String: Any], workspace: NSWorkspace = .shared) {
        guard let windowID = info[kCGWindowNumber as String] as? Int else {
            return nil
        }

        guard let rect = info[kCGWindowBounds as String] as? NSDictionary,
              let bounds = CGRect(dictionaryRepresentation: rect)
        else {
            return nil
        }

        guard let isOnScreen = info[kCGWindowIsOnscreen as String] as? Bool else {
            return nil
        }

        guard let windowLayer = info[kCGWindowLayer as String] as? Int else {
            return nil
        }

        self.windowID = CGWindowID(windowID)
        self.title = info[kCGWindowName as String] as? String
        self.owningApplication = RunningApplication(info: info, workspace: workspace)
        self.width = Int(bounds.size.width)
        self.height = Int(bounds.size.height)
        self.windowLayer = windowLayer
        self.isOnScreen = isOnScreen
        self.previewImage = nil
    }
}

#endif
