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

@frozen
public enum HTTPError: LocalizedError, CustomStringConvertible, Hashable {
    case invalidHTTPResponse
    case noDataInResponse
    case unacceptableStatusCode(Int)
    case unacceptableContentType(String?)
    case unauthorized
    case resourceNotFound(String)

    public var description: String {
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

    public var errorDescription: String? {
        description
    }
}
