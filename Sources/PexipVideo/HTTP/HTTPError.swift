import Foundation

enum HTTPError: LocalizedError {
    case invalidHTTPResponse
    case unacceptableStatusCode(Int)
    case unacceptableContentType(String?)
    
    var errorDescription: String {
        switch self {
        case .invalidHTTPResponse:
            return "No HTTP response received"
        case .unacceptableStatusCode(let statusCode):
            return "Unacceptable status code: \(statusCode)"
        case .unacceptableContentType(let mimeType):
            return "Unacceptable content type: \(mimeType ?? "?")"
        }
    }
}
