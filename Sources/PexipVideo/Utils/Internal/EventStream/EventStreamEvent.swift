import Foundation

struct EventStreamEvent: Hashable {
    let id: String?
    let name: String?
    var data: String?
    var retry: String?

    // Reconnection time in seconds
    var reconnectionTime: TimeInterval? {
        retry.flatMap {
            TimeInterval($0.trimmingCharacters(in: .whitespaces))
        }.map {
            $0 / 1000
        }
    }
}
