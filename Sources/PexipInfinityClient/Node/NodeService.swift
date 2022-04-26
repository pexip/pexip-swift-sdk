import Foundation
import PexipUtils

// MARK: - Protocol

public protocol NodeService {
    var baseURL: URL { get }
    /**
     Checks whether a Conferencing Node is in maintenance mode.
     - Parameters:
       - nodeAddress: a node address in the form of https://example.com
     - Returns: False if the node is in maintenance mode, true otherwise
     - Throws: `NodeError.nodeNotFound` if supplied `nodeAddress` doesn't have a deployment
     - Throws: `HTTPError.unacceptableStatusCode` if the response wasn't handled by the client
     - Throws: `Error` if another type of error was encountered during operation
     */
    func status() async throws -> Bool
    func conference(alias: ConferenceAlias) -> ConferenceService
}

// MARK: - Implementation

struct DefaultNodeService: NodeService {
    let baseURL: URL
    let client: HTTPClient
    var decoder = JSONDecoder()
    var logger: Logger?

    func status() async throws -> Bool {
        let request = URLRequest(
            url: baseURL.appendingPathComponent("status"),
            httpMethod: .GET
        )
        let (_, response) = try await client.data(for: request, validate: false)

        switch response.statusCode {
        case 200:
            return true
        case 404:
            throw HTTPError.resourceNotFound("Node")
        case 503:
            return false
        default:
            throw HTTPError.unacceptableStatusCode(response.statusCode)
        }
    }

    func conference(alias: ConferenceAlias) -> ConferenceService {
        let url =  baseURL.appendingPathComponent("conferences/\(alias.uri)")
        return DefaultConferenceService(
            baseURL: url,
            client: client,
            decoder: decoder,
            logger: logger
        )
    }
}
