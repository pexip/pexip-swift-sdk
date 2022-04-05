public struct CallConfiguration {
    static let googleStunServers = [
        "stun:stun.l.google.com:19302",
        "stun:stun1.l.google.com:19302",
        "stun:stun2.l.google.com:19302",
        "stun:stun3.l.google.com:19302",
        "stun:stun4.l.google.com:19302"
    ]

    /// Quality profile of the call.
    public var qualityProfile: QualityProfile
    /// Media features of the call.
    public var mediaFeatures: MediaFeature
    /// Use Google stun servers as backup.
    public var useGoogleStunServersAsBackup: Bool
    /// Show presentation-in-mix instead of separate presentation streams.
    public var showPresentationInMix: Bool

    var backupIceServers: [String] {
        useGoogleStunServersAsBackup ? Self.googleStunServers : []
    }

    /**
     Creates a call configuration with given settings.
     - Parameters:
        - qualityProfile: Quality profile of the call.
        - mediaFeatures: Media features of the call.
        - useGoogleStunServersAsBackup: Use Google stun servers as backup.
        - showPresentationInMix: Show presentation-in-mix instead of separate presentation streams.
     */
    public init(
        qualityProfile: QualityProfile = .default,
        mediaFeatures: MediaFeature = .all,
        useGoogleStunServersAsBackup: Bool = true,
        showPresentationInMix: Bool = false
    ) {
        self.qualityProfile = qualityProfile
        self.mediaFeatures = mediaFeatures
        self.useGoogleStunServersAsBackup = useGoogleStunServersAsBackup
        self.showPresentationInMix = showPresentationInMix
    }
}
