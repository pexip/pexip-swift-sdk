#if os(iOS)

import Foundation
import Network

extension NWConnection {
    func receive(completion: @escaping (
        _ content: Data?,
        _ contentContext: NWConnection.ContentContext?,
        _ isComplete: Bool,
        _ error: NWError?
    ) -> Void) {
        // The TCP maximum package size - 64K
        receive(
            minimumIncompleteLength: 1,
            maximumLength: 65_536,
            completion: completion
        )
    }
}

#endif
