import Foundation

enum NodeError: Hashable, LocalizedError {
    case invalidNodeURL(String)
    case nodeNotFound
}
