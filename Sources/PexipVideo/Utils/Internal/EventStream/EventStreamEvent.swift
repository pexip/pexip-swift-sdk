import Foundation

struct EventStreamEvent: Hashable {
    let id: String?
    let name: String?
    let data: String?
    let retry: String?

    // Reconnection time in seconds
    var reconnectionTime: TimeInterval? {
        retry.flatMap {
            TimeInterval($0.trimmingCharacters(in: .whitespaces))
        }.map {
            $0 / 1000
        }
    }
}
