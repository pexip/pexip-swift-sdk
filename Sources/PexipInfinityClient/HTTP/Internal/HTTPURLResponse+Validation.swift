import Foundation

extension HTTPURLResponse {
    func validate(for request: URLRequest) throws {
        try validateStatusCode()
        try validateContentType(for: request)
    }

    func validateStatusCode(_ acceptableStatusCodes: Range<Int> = 200..<300) throws {
        guard acceptableStatusCodes.contains(statusCode) else {
            throw HTTPError.unacceptableStatusCode(statusCode)
        }
    }

    func validateContentType(for request: URLRequest) throws {
        guard let contentType = request.value(forHTTPHeaderName: .contentType) else {
            return
        }
        try validateContentType([contentType])
    }

    func validateContentType(_ acceptableContentTypes: Set<String>) throws {
        guard let mimeType, acceptableContentTypes.contains(mimeType) else {
            throw HTTPError.unacceptableContentType(mimeType)
        }
    }
}
