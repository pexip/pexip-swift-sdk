public struct TokenRequest {
    /// The name by which this participant should be known
    public var displayName: String
    /// User-supplied PIN (if required)
    public var pin: String?
    /// Conference to connect to (when being used with a Virtual Reception)
    public var conferenceExtension: String?
    /// The identity provider used to proceed with SSO flow
    public var idp: IdentityProvider?
    /// The ssoToken received from the SSO flow
    public var ssoToken: String?

    // MARK: - Init

    /**
     - Parameters:
        - displayName: The name by which this participant should be known
        - pin: User-supplied PIN (if required)
        - conferenceExtension: Conference to connect to (when being used with a Virtual Reception)
        - idp: The identity provider used to proceed with SSO flow
        - ssoToken: The ssoToken received from the SSO flow
     */
    public init(
        displayName: String,
        pin: String? = nil,
        conferenceExtension: String? = nil,
        idp: IdentityProvider? = nil,
        ssoToken: String? = nil
    ) {
        self.displayName = displayName
        self.pin = pin
        self.conferenceExtension = conferenceExtension
        self.idp = idp
        self.ssoToken = ssoToken
    }
}
