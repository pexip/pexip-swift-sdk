import Foundation
import PexipCore

actor ConferenceSignalingChannel: SignalingChannel {
    private typealias CallDetailsTask = Task<CallDetails, Error>

    let iceServers: [IceServer]
    private(set) var pwds = [String: String]()

    var callId: UUID? {
        get async {
            try? await callsRequestTask?.value.id
        }
    }

    private let participantService: ParticipantService
    private let tokenStore: TokenStore<ConferenceToken>
    private let roster: Roster
    private let logger: Logger?
    private var callsRequestTask: CallDetailsTask?

    // MARK: - Init

    init(
        participantService: ParticipantService,
        tokenStore: TokenStore<ConferenceToken>,
        roster: Roster,
        iceServers: [IceServer],
        logger: Logger? = nil
    ) {
        self.participantService = participantService
        self.tokenStore = tokenStore
        self.roster = roster
        self.iceServers = iceServers
        self.logger = logger
    }

    // MARK: - MediaConnectionSignaling

    func sendOffer(
        callType: String,
        description: String,
        presentationInMain: Bool
    ) async throws -> String? {
        let token = try await tokenStore.token()
        let callService = try await callService
        let callId = await self.callId
        let isUpdate = callService != nil && callId != nil

        pwds = sdpPwds(from: description)
        callsRequestTask = CallDetailsTask {
            if let callService, let callId {
                let sdp = try await callService.update(
                    sdp: description,
                    token: token
                )
                return CallDetails(id: callId, sdp: sdp)
            } else {
                return try await participantService.calls(
                    fields: CallsFields(
                        callType: callType,
                        sdp: description,
                        present: presentationInMain ? .main : nil
                    ),
                    token: token
                )
            }
        }

        var remoteDescription = try await callsRequestTask!.value.sdp
        remoteDescription = remoteDescription?.isEmpty == true
            ? nil
            : remoteDescription

        if remoteDescription != nil, !isUpdate {
            try await ack(sdp: nil)
        }

        return remoteDescription
    }

    func sendAnswer(_ description: String) async throws {
        pwds = sdpPwds(from: description)
        try await ack(sdp: description)
    }

    func addCandidate(_ candidate: String, mid: String?) async throws {
        guard let callService = try await callService else {
            logger?.warn("Tried to send a new ICE candidate before starting a call")
            throw ConferenceSignalingError.callNotStarted
        }

        guard !pwds.isEmpty else {
            logger?.warn("ConferenceSignaling.onCandidate - pwds are not set")
            throw ConferenceSignalingError.pwdsMissing
        }

        guard let ufrag = candidateUfrag(from: candidate) else {
            logger?.warn("ConferenceSignaling.onCandidate - ufrag is not set")
            throw ConferenceSignalingError.ufragMissing
        }

        try await callService.newCandidate(
            iceCandidate: IceCandidate(
                candidate: candidate,
                mid: mid,
                ufrag: ufrag,
                pwd: pwds[ufrag]
            ),
            token: await tokenStore.token()
        )
    }

    @discardableResult
    func dtmf(signals: DTMFSignals) async throws -> Bool {
        guard let callService = try await callService else {
            logger?.warn("Tried to send DTMF signals before starting a call")
            throw ConferenceSignalingError.callNotStarted
        }
        return try await callService.dtmf(
            signals: signals,
            token: tokenStore.token()
        )
    }

    @discardableResult
    func muteVideo(_ muted: Bool) async throws -> Bool {
        if muted {
            return try await participantService.videoMuted(token: tokenStore.token())
        }

        return try await participantService.videoUnmuted(token: tokenStore.token())
    }

    @discardableResult
    func muteAudio(_ muted: Bool) async throws -> Bool {
        let token = try await tokenStore.token()

        guard token.role == .host else {
            return false
        }

        if muted {
            return try await participantService.mute(token: token)
        }

        return try await participantService.unmute(token: token)
    }

    @discardableResult
    func takeFloor() async throws -> Bool {
        guard roster.currentParticipant?.isPresenting == false else {
            return false
        }

        let token = try await tokenStore.token()
        try await participantService.takeFloor(token: token)
        return true
    }

    @discardableResult
    func releaseFloor() async throws -> Bool {
        guard roster.currentParticipant?.isPresenting == true else {
            return false
        }

        let token = try await tokenStore.token()
        try await participantService.releaseFloor(token: token)
        return true
    }

    // MARK: - Private

    private var callService: CallService? {
        get async throws {
            guard let callDetailsTask = callsRequestTask else {
                return nil
            }
            return try await participantService.call(id: callDetailsTask.value.id)
        }
    }

    private func ack(sdp: String?) async throws {
        guard let callService = try await callService else {
            logger?.warn("Tried to ack before starting a call")
            return
        }

        _ = try await callService.ack(
            sdp: sdp,
            token: await tokenStore.token()
        )
    }

    private func candidateUfrag(from candidate: String) -> String? {
        Regex.candicateUfrag.match(candidate)?.groupValue(at: 1)
    }

    private func sdpPwds(from description: String) -> [String: String] {
        var result = [String: String]()
        var iterator = description.components(separatedBy: "\r\n").makeIterator()

        while let line = iterator.next() {
            guard let ufrag = Regex.sdpUfrag.match(line)?.groupValue(at: 1) else {
                continue
            }
            guard let nextLine = iterator.next() else {
                break
            }
            guard let pwd = Regex.sdpPwd.match(nextLine)?.groupValue(at: 1) else {
                continue
            }
            result[ufrag] = pwd
        }

        return result
    }
}

// MARK: - Private extensions

private extension PexipCore.Regex {
    static let sdpUfrag = Regex("^a=ice-ufrag:(.+)$")
    static let sdpPwd = Regex("^a=ice-pwd:(.+)$")
    static let candicateUfrag = Regex(".*\\bufrag\\s+(.+?)\\s+.*")
}
