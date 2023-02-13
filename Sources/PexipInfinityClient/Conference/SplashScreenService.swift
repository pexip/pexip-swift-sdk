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

/// Conference splash screen service.
public protocol SplashScreenService {
    /**
     Fetches all available splash screens.
     - Parameters:
       - token: Current valid API token
     - Returns: A dictionary of splash screen objects
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func splashScreens(token: ConferenceToken) async throws -> [String: SplashScreen]

    /**
     - Parameters:
        - background: Splash screen background object
        - token: Current valid API token
     - Returns: The background image url for the given splash screen.
     */
    func backgroundURL(
        for background: SplashScreen.Background,
        token: ConferenceToken
    ) -> URL?
}
