import Foundation

final class HTTPClient {
    var acceptableStatusCodes: Range<Int> = 200..<300
    var acceptableContentTypes = Set(["application/json"])
    
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Init
    
    init(protocolClasses: [AnyClass] = []) {
        let configuration: URLSessionConfiguration = .ephemeral
        configuration.timeoutIntervalForRequest = 10
        configuration.protocolClasses = protocolClasses

        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Requests
    
    func get<Output: Decodable>(
        url: URL,
        queryItems: [URLQueryItem] = [],
        headers: [HTTPHeader] = []
    ) async throws -> Output {
        var request = URLRequest(url: url, httpMethod: .GET, headers: headers)
        
        if !queryItems.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = queryItems
            request.url = components?.url
        }
        
        return try await json(for: request)
    }
    
    func post<Input: Encodable, Output: Decodable>(
        url: URL,
        parameters: Input,
        headers: [HTTPHeader] = []
    ) async throws -> Output {
        var request = URLRequest(url: url, httpMethod: .POST, headers: headers)
        request.setHeader(.contentType("application/json"))
        request.httpBody = try encoder.encode(parameters)
        return try await json(for: request)
    }
    
    func post<Input: Encodable>(
        url: URL,
        parameters: Input,
        headers: [HTTPHeader] = []
    ) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url, httpMethod: .POST, headers: headers)
        request.setHeader(.contentType("application/json"))
        request.httpBody = try encoder.encode(parameters)
        
        let (data, response) = try await session.data(for: request)
        
        if let response = response as? HTTPURLResponse {
            return (data, response)
        } else {
            throw HTTPError.invalidHTTPResponse
        }
    }
    
    private func json<T: Decodable>(for request: URLRequest) async throws -> T {
        let data = try await data(for: request)
        return try decoder.decode(T.self, from: data)
    }
    
    private func data(for request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        
        guard let response = response as? HTTPURLResponse else {
            throw HTTPError.invalidHTTPResponse
        }

        guard acceptableStatusCodes.contains(response.statusCode) else {
            throw HTTPError.unacceptableStatusCode(response.statusCode)
        }

        guard let mimeType = response.mimeType, acceptableContentTypes.contains(mimeType) else {
            throw HTTPError.unacceptableContentType(response.mimeType)
        }
        
        return data
    }
}

// MARK: - Errors

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

// MARK: - Private extensions

private extension URLRequest {
    init(url: URL, httpMethod: HTTPMethod, headers: [HTTPHeader] = []) {
        self.init(url: url)
        self.httpMethod = httpMethod.rawValue
        headers.forEach { setHeader($0) }
    }
    
    mutating func setHeader(_ header: HTTPHeader) {
        setValue(header.value, forHTTPHeaderField: header.name)
    }
}

@available(iOS, deprecated: 15.0, message: "Use the built-in API instead")
private extension URLSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: request) { data, response, error in
                guard let data = data, let response = response else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }

                continuation.resume(returning: (data, response))
            }

            task.resume()
        }
    }
}
