public struct ConferenceTokenRequestFields: Encodable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case conferenceExtension = "conference_extension"
        case chosenIdpId = "chosen_idp"
        case ssoToken = "sso_token"
    }

    /// The name by which this participant should be known
    public var displayName: String

    /// Conference to connect to (when being used with a Virtual Reception)
    public var conferenceExtension: String?

    /// The identity provider used to proceed with SSO flow
    public var chosenIdpId: String?

    /// The ssoToken received from the SSO flow
    public var ssoToken: String?

    // MARK: - Init

    /**
     - Parameters:
        - displayName: The name by which this participant should be known
        - conferenceExtension: Conference to connect to (when being used with a Virtual Reception)
        - idp: The identity provider used to proceed with SSO flow
        - ssoToken: The ssoToken received from the SSO flow
     */
    public init(
        displayName: String,
        conferenceExtension: String? = nil,
        idp: IdentityProvider? = nil,
        ssoToken: String? = nil
    ) {
        self.displayName = displayName
        self.conferenceExtension = conferenceExtension
        self.chosenIdpId = idp?.id
        self.ssoToken = ssoToken
    }
}
