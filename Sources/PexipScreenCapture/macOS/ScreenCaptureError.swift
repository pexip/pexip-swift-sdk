#if os(macOS)

import Foundation
import CoreGraphics

/// An object that represents the error occured during screen capture.
@frozen
public enum ScreenCaptureError: LocalizedError, CustomStringConvertible, Hashable {
    case cgError(CGError)
    case noScreenMediaSourceAvailable

    public var description: String {
        switch self {
        case .cgError(let errorCode):
            return "Screen capture error, CGError code: \(errorCode)"
        case .noScreenMediaSourceAvailable:
            return "No screen media source available."
        }
    }

    public var errorDescription: String? {
        description
    }
}

#endif
