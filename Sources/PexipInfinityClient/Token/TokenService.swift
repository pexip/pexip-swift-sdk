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

public protocol TokenService {
    /**
     Refreshes the token to get a new one.

     - Parameter token: Current valid token
     - Returns: New token
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func refreshToken(_ token: InfinityToken) async throws -> TokenRefreshResponse

    /**
     Releases the token (effectively a disconnect for the participant).

     - Parameter token: Current valid token
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func releaseToken(_ token: InfinityToken) async throws
}
