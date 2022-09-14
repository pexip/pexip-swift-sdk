import Foundation

@frozen
public enum InfinityTokenError: LocalizedError, CustomStringConvertible, Hashable {
    case tokenExpired

    public var description: String {
        switch self {
        case .tokenExpired:
            return "Token is expired"
        }
    }

    public var errorDescription: String? {
        description
    }
}
