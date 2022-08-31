import WebRTC
import PexipCore

extension RTCConfiguration {
    static func defaultConfiguration(
        withIceServers iceServers: [IceServer],
        dscp: Bool
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
        configuration.enableDscp = dscp
        configuration.continualGatheringPolicy = .gatherContinually
        return configuration
    }
}
