import Foundation

@frozen
public enum ValidationError: LocalizedError, CustomStringConvertible, Hashable {
    case invalidArgument

    public var description: String {
        switch self {
        case .invalidArgument:
            return "Invalid argument"
        }
    }

    public var errorDescription: String? {
        description
    }
}
