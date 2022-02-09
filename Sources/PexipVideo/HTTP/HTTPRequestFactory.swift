import Foundation

struct HTTPRequestFactory {
    let baseURL: URL
    let authTokenProvider: AuthTokenProvider

    func request(
        withName name: String,
        method: HTTPMethod,
        token: AuthToken? = nil
    ) async throws -> URLRequest {
        let url = baseURL.appendingPathComponent(name)
        var request = URLRequest(url: url, httpMethod: method)

        request.setHTTPHeader(.defaultUserAgent)

        if let token = token {
            request.setAuthToken(token)
        } else if let token = try await authTokenProvider.authToken() {
            request.setAuthToken(token)
        }

        return request
    }
}

// MARK: - Private extensions

private extension URLRequest {
    mutating func setAuthToken(_ token: AuthToken) {
        setHTTPHeader(.init(name: "token", value: token.value))
    }
}
