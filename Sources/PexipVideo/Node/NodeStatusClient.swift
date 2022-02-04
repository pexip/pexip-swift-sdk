import Foundation

// MARK: - Protocol

/// Pexip client REST API v2.
protocol NodeStatusClientProtocol {
    /// Checks whether a Conferencing Node is in maintenance mode.
    /// - Parameters:
    ///   - nodeAddress: a node address in the form of https://example.com
    /// - Returns: True if the node is in maintenance mode, false otherwise
    /// - Throws: `NodeError.nodeNotFound` if supplied `nodeAddress` doesn't have a deployment
    /// - Throws: `HTTPError.unacceptableStatusCode` if the response wasn't handled by the client
    /// - Throws: `Error` if another type of error was encountered during operation
    func isInMaintenanceMode(nodeAddress: URL) async throws -> Bool
}

// MARK: - Implementation

struct NodeStatusClient: NodeStatusClientProtocol {
    private let httpSession: HTTPSession

    // MARK: - Init

    init(httpSession: HTTPSession) {
        self.httpSession = httpSession
    }

    // MARK: - API

    func isInMaintenanceMode(nodeAddress: URL) async throws -> Bool {
        let (_, response) = try await httpSession.data(
            for: URLRequest(url: nodeAddress, httpMethod: .GET),
            validate: false
        )

        switch response.statusCode {
        case 200:
            return false
        case 404:
            throw NodeError.nodeNotFound
        case 503:
            return true
        default:
            throw HTTPError.unacceptableStatusCode(response.statusCode)
        }
    }
}
