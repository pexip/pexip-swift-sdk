import Foundation
import PexipUtils

// MARK: - Protocol

public protocol InfinityService {
    /**
     Creates a new ``RequestBuilder``.
     - Parameters:
        - url: A conferencing node address in the form of https://example.com
     - Returns: A new instance of ``RequestBuilder``
     */
    func node(url: URL) -> NodeService
}

// MARK: - Implementation

struct DefaultInfinityService: InfinityService {
    let client: HTTPClient
    var decoder = JSONDecoder()
    var logger: Logger?

    func node(url: URL) -> NodeService {
        let url = url.appendingPathComponent("api/client/v2")
        return DefaultNodeService(
            baseURL: url,
            client: client,
            decoder: decoder,
            logger: logger
        )
    }
}
