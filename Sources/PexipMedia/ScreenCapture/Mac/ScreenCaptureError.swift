#if os(macOS)

import Foundation
import CoreGraphics

/// An object that represents the error occured during screen capture.
public enum ScreenCaptureError: LocalizedError, CustomStringConvertible {
    case cgError(CGError)

    public var description: String {
        switch self {
        case .cgError(let errorCode):
            return "Screen capture error, CGError code: \(errorCode)"
        }
    }

    public var errorDescription: String? {
        description
    }
}

#endif
