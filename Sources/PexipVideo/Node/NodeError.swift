import Foundation

enum NodeError: LocalizedError {
    case invalidNodeURL(String)
    case nodeNotFound
}
