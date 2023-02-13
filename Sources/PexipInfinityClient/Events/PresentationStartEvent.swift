//
// Copyright 2022-2023 Pexip AS
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

/// An event that includes the information on which participant is presenting.
public struct PresentationStartEvent: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case presenterName = "presenter_name"
        case presenterUri = "presenter_uri"
    }

    /// The name of the presenter.
    public let presenterName: String

    /// The URI of the presenter.
    public let presenterUri: String

    /// Creates a new instance of ``PresentationStartEvent``
    ///
    /// - Parameters:
    ///   - presenterName: The name of the presenter
    ///   - presenterUri: The URI of the presenter
    public init(presenterName: String, presenterUri: String) {
        self.presenterName = presenterName
        self.presenterUri = presenterUri
    }
}
