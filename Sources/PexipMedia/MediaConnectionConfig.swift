public struct MediaConnectionConfig {
    public static let googleStunUrls = [
        "stun:stun.l.google.com:19302",
        "stun:stun1.l.google.com:19302",
        "stun:stun2.l.google.com:19302",
        "stun:stun3.l.google.com:19302",
        "stun:stun4.l.google.com:19302"
    ]
    public static let googleIceServer = IceServer(urls: googleStunUrls)

    public let iceServers: [IceServer]
    public let presentationInMain: Bool
    public let mainQualityProfile: QualityProfile

    public init(
        iceServers: [IceServer] = [],
        presentationInMain: Bool = false,
        mainQualityProfile: QualityProfile = .medium
    ) {
        let iceServers = iceServers.filter { !$0.urls.isEmpty }
        self.iceServers = iceServers.isEmpty
            ? [Self.googleIceServer]
            : iceServers
        self.presentationInMain = presentationInMain
        self.mainQualityProfile = mainQualityProfile
    }
}
