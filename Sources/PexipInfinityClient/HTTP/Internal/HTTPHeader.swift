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

/// A representation of a single HTTP header's name / value pair.
struct HTTPHeader: Hashable, CustomStringConvertible {
    enum Name: String {
        case authorization = "Authorization"
        case contentType = "Content-Type"
        case userAgent = "User-Agent"
        case token = "token"
    }

    let name: String
    let value: String
    var description: String { "\(name): \(value)" }

    init(name: String, value: String) {
        self.name = name
        self.value = value
    }

    static func authorization(username: String, password: String) -> HTTPHeader {
        let utf8 = "\(username):\(password)".utf8
        let base64 = Data(utf8).base64EncodedString()
        let value = "x-pexip-basic \(base64)"
        return HTTPHeader(name: Name.authorization.rawValue, value: value)
    }

    static func contentType(_ value: String) -> HTTPHeader {
        HTTPHeader(name: Name.contentType.rawValue, value: value)
    }

    static func userAgent(_ value: String) -> HTTPHeader {
        HTTPHeader(name: Name.userAgent.rawValue, value: value)
    }

    static func token(_ value: String) -> HTTPHeader {
        HTTPHeader(name: Name.token.rawValue, value: value)
    }

    // MARK: - Defaults

    /// User-Agent Header
    /// Example: `pexip-ios-sdk/0.0.1`
    static let defaultUserAgent: HTTPHeader = {
        let bundle = Bundle.main
        let name = bundle.name ?? "pexip-ios-sdk"
        let version = bundle.version ?? "Unknown"
        return .userAgent("\(name)/\(version)")
    }()
}

// MARK: - Private extensions

private extension Bundle {
    var name: String? {
        object(forInfoDictionaryKey: "CFBundleName") as? String
    }

    var version: String? {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
}
