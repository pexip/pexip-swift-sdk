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

public struct HTTPEventError: LocalizedError, CustomStringConvertible {
    public let response: HTTPURLResponse?
    public let dataStreamError: Error?
    public var statusCode: Int? {
        response?.statusCode
    }

    // MARK: - Init

    public init(response: HTTPURLResponse?, dataStreamError: Error?) {
        self.response = response
        self.dataStreamError = dataStreamError
    }

    // MARK: - LocalizedError

    public var description: String {
        if let dataStreamError {
            let errorDescription = dataStreamError.localizedDescription
            return "Event source disconnected with error: \(errorDescription)"
        } else if let statusCode = response?.statusCode {
            return "Event source connection closed, status code: \(statusCode)"
        }

        return "Event source connection unexpectedly closed"
    }

    public var errorDescription: String? {
        description
    }
}
