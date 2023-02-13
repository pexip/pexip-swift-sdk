//
// Copyright 2022 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
