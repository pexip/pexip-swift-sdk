#if os(macOS)

import Foundation
import CoreGraphics

/// An object that represents the error occured during screen capture.
public enum ScreenCaptureError: LocalizedError, CustomStringConvertible {
    case cgError(CGError)
    case noScreenVideoSourceAvailable

    public var description: String {
        switch self {
        case .cgError(let errorCode):
            return "Screen capture error, CGError code: \(errorCode)"
        case .noScreenVideoSourceAvailable:
            return "No screen video source available."
        }
    }

    public var errorDescription: String? {
        description
    }
}

#endif
