import Foundation

/// A node address container
public struct Node: Hashable {
    /// A node address in the form of https://example.com
    public let address: URL

    /// - Parameter address: A node address in the form of https://example.com
    public init(address: URL) {
        self.address = address
    }
}
