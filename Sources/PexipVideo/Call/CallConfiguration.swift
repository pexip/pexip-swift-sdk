public struct CallConfiguration {
    static let googleStunServers = [
        "stun:stun.l.google.com:19302",
        "stun:stun1.l.google.com:19302",
        "stun:stun2.l.google.com:19302",
        "stun:stun3.l.google.com:19302",
        "stun:stun4.l.google.com:19302"
    ]

    public var qualityProfile: QualityProfile
    public var mediaFeatures: MediaFeature
    public var useGoogleStunServersAsBackup: Bool

    var backupIceServers: [String] {
        useGoogleStunServersAsBackup ? CallConfiguration.googleStunServers : []
    }

    public init(
        qualityProfile: QualityProfile = .medium,
        mediaFeatures: MediaFeature = .all,
        useGoogleStunServersAsBackup: Bool = true
    ) {
        self.qualityProfile = qualityProfile
        self.mediaFeatures = mediaFeatures
        self.useGoogleStunServersAsBackup = useGoogleStunServersAsBackup
    }
}
