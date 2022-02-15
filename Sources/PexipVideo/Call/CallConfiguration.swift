public struct CallConfiguration {
    static let googleStunServers = [
        "stun:stun.l.google.com:19302",
        "stun:stun1.l.google.com:19302",
        "stun:stun2.l.google.com:19302",
        "stun:stun3.l.google.com:19302",
        "stun:stun4.l.google.com:19302"
    ]

    public var qualityProfile: CallQualityProfile
    public var supportsAudio: Bool
    public var supportsVideo: Bool
    public var useGoogleStunServersAsBackup: Bool

    var backupIceServers: [String] {
        useGoogleStunServersAsBackup ? CallConfiguration.googleStunServers : []
    }

    public init(
        qualityProfile: CallQualityProfile = .medium,
        supportsAudio: Bool = true,
        supportsVideo: Bool = true,
        useGoogleStunServersAsBackup: Bool = true
    ) {
        self.qualityProfile = qualityProfile
        self.supportsAudio = supportsAudio
        self.supportsVideo = supportsVideo
        self.useGoogleStunServersAsBackup = useGoogleStunServersAsBackup
    }
}
