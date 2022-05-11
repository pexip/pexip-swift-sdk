import WebRTC
import PexipMedia

extension RTCConfiguration {
    static func defaultConfiguration(
        withIceServers iceServers: [IceServer]
    ) -> RTCConfiguration {
        let configuration = RTCConfiguration()
        configuration.iceServers = iceServers.map {
            RTCIceServer(
                urlStrings: $0.urls,
                username: $0.username,
                credential: $0.password
            )
        }
        configuration.bundlePolicy = .maxBundle
        configuration.sdpSemantics = .unifiedPlan
        configuration.continualGatheringPolicy = .gatherContinually
        return configuration
    }
}
