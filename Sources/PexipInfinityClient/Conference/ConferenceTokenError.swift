//
// Copyright 2022-2024 Pexip AS
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
public enum ConferenceTokenError: LocalizedError, Hashable {
    /// The supplied `pin` is invalid
    case invalidPin
    /// If a PIN is required for a Host, but not for a Guest,
    /// and if you want to join as a Guest, you must still
    /// provide a `pin` with a value of "none"
    case pinRequired(guestPin: Bool)

    /// If the conference is a Virtual Reception, to join the target room,
    /// you must provide a `conferenceExtension` field,
    /// which contains the alias of the target conference
    case conferenceExtensionRequired(String)

    /// If SSO is required, you must choose one of the identity
    /// providers from the list of IdPs
    case ssoIdentityProviderRequired([IdentityProvider])

    /// Redirect to the chosen identity provider to complete SSO
    case ssoIdentityProviderRedirect(idp: IdentityProvider, url: URL)

    /// Cannot parse the response
    case tokenDecodingFailed
}

// MARK: - Decodable

extension ConferenceTokenError: Decodable {
    private enum CodingKeys: String, CodingKey {
        case guestPin = "guest_pin"
        case ext = "conference_extension"
        case idp
        case redirectURL = "redirect_url"
        case redirectIDP = "redirect_idp"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        func decode<T: Decodable>(
            _ type: T.Type,
            forKey key: CodingKeys
        ) throws -> T? {
            try container.decodeIfPresent(type, forKey: key)
        }

        if let guestPin = try decode(String.self, forKey: .guestPin) {
            self = .pinRequired(guestPin: guestPin == "required")
        } else if let ext = try decode(String.self, forKey: .ext) {
            self = .conferenceExtensionRequired(ext)
        } else if let idps = try decode([IdentityProvider].self, forKey: .idp) {
            self = .ssoIdentityProviderRequired(idps)
        } else if let url = try decode(URL.self, forKey: .redirectURL),
                  let idp = try decode(IdentityProvider.self, forKey: .redirectIDP) {
            self = .ssoIdentityProviderRedirect(idp: idp, url: url)
        } else {
            self = .tokenDecodingFailed
        }
    }
}
