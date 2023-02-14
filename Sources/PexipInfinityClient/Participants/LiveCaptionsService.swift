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

// MARK: - Protocol

public protocol LiveCaptionsService {
    /**
     Starts receiving live caption events.

     - Parameters:
        - token: Current valid API token
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func showLiveCaptions(token: ConferenceToken) async throws

    /**
     Stop receiving live caption events.

     - Parameters:
        - token: Current valid API token
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func hideLiveCaptions(token: ConferenceToken) async throws
}

// MARK: - Extensions

public extension LiveCaptionsService {
    /**
     Toggle live caption events.

     - Parameters:
        - enabled: Boolean indicating whether the live captions are enabled or not.
        - token: Current valid API token

     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func toggleLiveCaptions(_ enabled: Bool, token: ConferenceToken) async throws {
        if enabled {
            try await showLiveCaptions(token: token)
        } else {
            try await hideLiveCaptions(token: token)
        }
    }
}
