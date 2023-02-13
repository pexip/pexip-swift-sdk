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
