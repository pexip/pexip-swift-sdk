import Foundation

enum HTTPError: LocalizedError {
    case invalidHTTPResponse
    case unacceptableStatusCode(Int)
    case unacceptableContentType(String?)
    case unauthorized
    case resourceNotFound(String)
    
    var errorDescription: String {
        switch self {
        case .invalidHTTPResponse:
            return "No HTTP response received"
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
