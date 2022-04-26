import Foundation

public struct EventSourceEvent: Hashable {
    public let id: String?
    public let name: String?
    public var data: String?
    public var retry: String?

    // Reconnection time in seconds
    public var reconnectionTime: TimeInterval? {
        retry.flatMap {
            TimeInterval($0.trimmingCharacters(in: .whitespaces))
        }.map {
            $0 / 1000
        }
    }
}
