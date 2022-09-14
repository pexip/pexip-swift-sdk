import Foundation

extension URLRequest {
    init(url: URL, httpMethod: HTTPMethod) {
        self.init(url: url)
        self.httpMethod = httpMethod.rawValue
    }

    mutating func setHTTPHeader(_ header: HTTPHeader) {
        setValue(header.value, forHTTPHeaderField: header.name)
    }

    func value(forHTTPHeaderName name: HTTPHeader.Name) -> String? {
        value(forHTTPHeaderField: name.rawValue)
    }

    mutating func setQueryItems(_ queryItems: [URLQueryItem]) {
        if let url, !queryItems.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = queryItems
            self.url = components?.url
        }
    }

    mutating func setJSONBody<Input: Encodable>(
        _ parameters: Input,
        encoder: JSONEncoder = .init()
    ) throws {
        setHTTPHeader(.contentType("application/json"))
        httpBody = try encoder.encode(parameters)
    }

    var methodWithDescription: String {
        "\(httpMethod ?? "") \(description)"
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
