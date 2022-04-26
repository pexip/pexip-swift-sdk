import WebRTC

extension RTCConfiguration {
    static let googleStunServers = [
        "stun:stun.l.google.com:19302",
        "stun:stun1.l.google.com:19302",
        "stun:stun2.l.google.com:19302",
        "stun:stun3.l.google.com:19302",
        "stun:stun4.l.google.com:19302"
    ]

    static func defaultConfiguration(
        withIceServers iceServers: [String],
        useGoogleStunServersAsBackup: Bool
    ) -> RTCConfiguration {
        let iceServers = iceServers.isEmpty && useGoogleStunServersAsBackup
            ? Self.googleStunServers
            : iceServers

        let configuration = RTCConfiguration()
        configuration.iceServers = [RTCIceServer(urlStrings: iceServers)]
        configuration.sdpSemantics = .unifiedPlan
        configuration.continualGatheringPolicy = .gatherContinually
        configuration.bundlePolicy = .balanced
        configuration.rtcpMuxPolicy = .require
        configuration.tcpCandidatePolicy = .enabled
        configuration.disableLinkLocalNetworks = true
        return configuration
    }
}
