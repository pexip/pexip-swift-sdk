import Foundation

public struct Fingerprint: Hashable {
    public let type: String
    public let hash: String

    public var value: String {
        type + hash
    }

    public init(type: String, hash: String) {
        self.type = type
        self.hash = hash
    }
}
