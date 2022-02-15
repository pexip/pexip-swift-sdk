import WebRTC

// MARK: - Peer connection factory

extension RTCPeerConnectionFactory {
    static let `default`: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        #if targetEnvironment(simulator)
        let videoEncoderFactory = RTCVideoEncoderFactoryVP8()
        let videoDecoderFactory = RTCVideoDecoderFactoryVP8()
        #else
        let videoEncoderFactory = RTCVideoEncoderFactoryH264()
        let videoDecoderFactory = RTCVideoDecoderFactoryH264()
        #endif
        return RTCPeerConnectionFactory(
            encoderFactory: videoEncoderFactory,
            decoderFactory: videoDecoderFactory
        )
    }()
}

// MARK: - Peer connection

protocol RTCTrackManager: AnyObject {
    func add(_ track: RTCMediaStreamTrack, streamIds: [String]) -> RTCRtpSender?
    func removeTrack(_ sender: RTCRtpSender) -> Bool
}

extension RTCPeerConnection: RTCTrackManager {}

// MARK: - Configuration

extension RTCConfiguration {
    static func configuration(withIceServers iceServers: [String]) -> RTCConfiguration {
        let configuration = RTCConfiguration()
        configuration.iceServers = [RTCIceServer(urlStrings: iceServers)]
        configuration.sdpSemantics = .unifiedPlan
        configuration.bundlePolicy = .balanced
        configuration.iceTransportPolicy = iceServers.isEmpty ? .all : .relay
        configuration.rtcpMuxPolicy = .require
        configuration.tcpCandidatePolicy = .enabled
        configuration.disableLinkLocalNetworks = true
        return configuration
    }
}

// MARK: - Media constraints

extension RTCMediaConstraints {
    static let empty = RTCMediaConstraints(
        mandatoryConstraints: nil,
        optionalConstraints: nil
    )

    static func constraints(withEnabledVideo video: Bool, audio: Bool) -> RTCMediaConstraints {
        func mediaConstraintsValue(from bool: Bool) -> String {
            bool ? kRTCMediaConstraintsValueTrue : kRTCMediaConstraintsValueFalse
        }

        return RTCMediaConstraints(
            mandatoryConstraints: [
                kRTCMediaConstraintsOfferToReceiveVideo: mediaConstraintsValue(from: video),
                kRTCMediaConstraintsOfferToReceiveAudio: mediaConstraintsValue(from: audio)
            ],
            optionalConstraints: [
                "internalSctpDataChannels": kRTCMediaConstraintsValueFalse,
                "DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue
            ]
        )
    }
}
