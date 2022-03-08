import WebRTC

// MARK: - Peer connection factory

extension RTCPeerConnectionFactory {
    static let `default`: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        #if targetEnvironment(simulator)
        let videoEncoderFactory = WebRTCVideoEncoderFactoryVP8()
        let videoDecoderFactory = WebRTCVideoDecoderFactoryVP8()
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
        configuration.continualGatheringPolicy = .gatherContinually
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

    static func constraints(receiveVideo: Bool, receiveAudio: Bool) -> RTCMediaConstraints {
        func mediaConstraintsValue(from bool: Bool) -> String {
            bool ? kRTCMediaConstraintsValueTrue : kRTCMediaConstraintsValueFalse
        }

        return RTCMediaConstraints(
            mandatoryConstraints: [
                kRTCMediaConstraintsOfferToReceiveVideo: mediaConstraintsValue(from: receiveVideo),
                kRTCMediaConstraintsOfferToReceiveAudio: mediaConstraintsValue(from: receiveAudio)
            ],
            optionalConstraints: [
                "internalSctpDataChannels": kRTCMediaConstraintsValueFalse,
                "DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue
            ]
        )
    }
}

// MARK: - Signaling State

extension RTCSignalingState {
    var debugDescription: String {
        switch self {
        case .stable:
            return "Stable"
        case .haveLocalOffer:
            return "HaveLocalOffer"
        case .haveLocalPrAnswer:
            return "HaveLocalPrAnswer"
        case .haveRemoteOffer:
            return "HaveRemoteOffer"
        case .haveRemotePrAnswer:
            return "HaveRemotePrAnswer"
        case .closed:
            return "Closed"
        @unknown default:
            return "Unknown"
        }
    }
}

// MARK: - Connection State

extension RTCIceConnectionState {
    var debugDescription: String {
        switch self {
        case .new:
            return "New"
        case .checking:
            return "Checking"
        case .connected:
            return "Connected"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        case .disconnected:
            return "Disconnected"
        case .closed:
            return "Closed"
        case .count:
            return "Count"
        @unknown default:
            return "Unknown"
        }
    }
}

// MARK: - Ice Gathering State

extension RTCIceGatheringState {
    var debugDescription: String {
        switch self {
        case .new:
            return "New"
        case .gathering:
            return "Gathering"
        case .complete:
            return "Complete"
        @unknown default:
            return "Unknown"
        }
    }
}
