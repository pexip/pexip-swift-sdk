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

public struct ConferenceTokenRequestFields: Encodable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case conferenceExtension = "conference_extension"
        case chosenIdpId = "chosen_idp"
        case ssoToken = "sso_token"
        case directMedia = "direct_media"
    }

    /// The name by which this participant should be known
    public var displayName: String

    /// Conference to connect to (when being used with a Virtual Reception)
    public var conferenceExtension: String?

    /// The identity provider used to proceed with SSO flow
    public var chosenIdpId: String?

    /// The ssoToken received from the SSO flow
    public var ssoToken: String?

    /// Indicates whether direct media is supported by the client.
    public var directMedia: Bool

    // MARK: - Init

    /**
     - Parameters:
        - displayName: The name by which this participant should be known
        - conferenceExtension: Conference to connect to (when being used with a Virtual Reception)
        - idp: The identity provider used to proceed with SSO flow
        - ssoToken: The ssoToken received from the SSO flow
        - directMedia: Indicates whether direct media is supported by the client
                       (disabled by default).
     */
    public init(
        displayName: String,
        conferenceExtension: String? = nil,
        idp: IdentityProvider? = nil,
        ssoToken: String? = nil,
        directMedia: Bool = false
    ) {
        self.displayName = displayName
        self.conferenceExtension = conferenceExtension
        self.chosenIdpId = idp?.id
        self.ssoToken = ssoToken
        self.directMedia = directMedia
    }
}
