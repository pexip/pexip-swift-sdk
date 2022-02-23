import Foundation

enum HTTPError: LocalizedError, CustomStringConvertible, Hashable {
    case invalidHTTPResponse
    case noDataInResponse
    case unacceptableStatusCode(Int)
    case unacceptableContentType(String?)
    case unauthorized
    case resourceNotFound(String)

    var description: String {
        switch self {
        case .invalidHTTPResponse:
            return "No HTTP response received"
        case .noDataInResponse:
            return "No data in response"
        case .unacceptableStatusCode(let statusCode):
            return "Unacceptable status code: \(statusCode)"
        case .unacceptableContentType(let mimeType):
            return "Unacceptable content type: \(mimeType ?? "?")"
        case .unauthorized:
            return "The request lacks valid authentication credentials for the target resource"
        case .resourceNotFound(let resource):
            return "The server cannot find the requested \(resource)"
        }
    }
}
