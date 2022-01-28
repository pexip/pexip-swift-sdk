import Foundation

// MARK: - Protocol

protocol NodeStatusClientProtocol {
    /// Checks whether a Conferencing Node is in maintenance mode.
    ///
    /// - Returns: True/False
    func isInMaintenanceMode(apiURL: URL) async throws -> Bool
}

// MARK: - Implementation

struct NodeStatusClient: NodeStatusClientProtocol {
    private let urlSession: URLSession
    
    // MARK: - Init
    
    init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
    
    // MARK: - API

    func isInMaintenanceMode(apiURL: URL) async throws -> Bool {
        let (_, response) = try await urlSession.http.data(
            for: URLRequest(url: apiURL, httpMethod: .GET),
            validate: false
        )
        
        switch response.statusCode {
        case 200:
            return false
        case 503:
            return true
        default:
            throw NodeError.nodeNotFound
        }
    }
}
