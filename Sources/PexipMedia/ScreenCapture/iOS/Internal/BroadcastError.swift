#if os(iOS)

import Foundation

/// An object that represents the error occured during IPC.
public enum BroadcastError: LocalizedError, CustomStringConvertible {
    case invalidHeader

    public var description: String {
        switch self {
        case .invalidHeader:
            return "Invalid broadcast header"
        }
    }

    public var errorDescription: String? {
        description
    }
}

#endif
