import Foundation

struct HTTPRequestFactory {
    let baseURL: URL
    let authTokenProvider: AuthTokenProvider

    func request(withName name: String, method: HTTPMethod) async throws -> URLRequest {
        let url = baseURL.appendingPathComponent(name)
        var request = URLRequest(url: url, httpMethod: method)

        request.setHTTPHeader(.defaultUserAgent)

        if let token = try await authTokenProvider.authToken() {
            request.setHTTPHeader(.init(name: "token", value: token.value))
        }

        return URLRequest(url: url, httpMethod: method)
    }
}
