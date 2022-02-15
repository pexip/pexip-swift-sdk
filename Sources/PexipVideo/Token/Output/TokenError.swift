import Foundation

public enum TokenError: LocalizedError, Hashable {
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

extension TokenError: Decodable {
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
        } else if
            let url = try decode(URL.self, forKey: .redirectURL),
            let idp = try decode(IdentityProvider.self, forKey: .redirectIDP)
        {
            self = .ssoIdentityProviderRedirect(idp: idp, url: url)
        } else {
            self = .tokenDecodingFailed
        }
    }
}
