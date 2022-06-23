import PexipMedia
import PexipInfinityClient
import PexipUtils

actor ConferenceSignaling: MediaConnectionSignaling {
    private typealias CallDetailsTask = Task<CallDetails, Error>

    let iceServers: [IceServer]

    private let participantService: ParticipantService
    private let tokenStore: TokenStore
    private let logger: Logger?
    private var pwds = [String: String]()
    private var callsRequestTask: CallDetailsTask?

    // MARK: - Init

    init(
        participantService: ParticipantService,
        tokenStore: TokenStore,
        iceServers: [IceServer],
        logger: Logger?
    ) {
        self.participantService = participantService
        self.tokenStore = tokenStore
        self.iceServers = iceServers
        self.logger = logger
    }

    deinit {
        Task {
            await callsRequestTask?.cancel()
        }
    }

    // MARK: - MediaConnectionSignaling

    func sendOffer(
        callType: String,
        description: String,
        presentationInMain: Bool
    ) async throws -> String {
        let token = try await tokenStore.token()

        if let callService = try await callService {
            return try await callService.update(
                sdp: description,
                token: token
            )
        } else {
            pwds = sdpPwds(from: description)
            callsRequestTask = CallDetailsTask {
                try await participantService.calls(
                    fields: CallsFields(
                        callType: callType,
                        sdp: description,
                        present: presentationInMain ? .main : nil
                    ),
                    token: token
                )
            }
            _ = try await callService?.ack(token: await tokenStore.token())
            return try await callsRequestTask!.value.sdp
        }
    }

    func addCandidate(sdp: String, mid: String?) async throws {
        guard let callService = try await callService else {
            logger?.warn("Tried to send a new ICE candidate before starting a call")
            return
        }

        guard !pwds.isEmpty else {
            logger?.warn("ConferenceSignaling.onCandidate - pwds are not set")
            return
        }

        guard let ufrag = candidateUfrag(from: sdp) else {
            logger?.warn("ConferenceSignaling.onCandidate - ufrag are not set")
            return
        }

        try await callService.newCandidate(
            iceCandidate: IceCandidate(
                candidate: sdp,
                mid: mid,
                ufrag: ufrag,
                pwd: pwds[ufrag]
            ),
            token: await tokenStore.token()
        )
    }

    func muteVideo(_ muted: Bool) async throws {
        if muted {
            try await participantService.videoMuted(token: tokenStore.token())
        } else {
            try await participantService.videoUnmuted(token: tokenStore.token())
        }
    }

    func muteAudio(_ muted: Bool) async throws {
        let token = try await tokenStore.token()

        guard token.role == .host else {
            return
        }

        if muted {
            try await participantService.mute(token: token)
        } else {
            try await participantService.unmute(token: token)
        }
    }

    func takeFloor() async throws {
        let token = try await tokenStore.token()
        try await participantService.takeFloor(token: token)
    }

    func releaseFloor() async throws {
        let token = try await tokenStore.token()
        try await participantService.releaseFloor(token: token)
    }

    // MARK: - Private

    private var callService: CallService? {
        get async throws {
            if let callDetailsTask = callsRequestTask {
                return try await participantService.call(id: callDetailsTask.value.id)
            } else {
                return nil
            }
        }
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

private extension PexipUtils.Regex {
    static let sdpUfrag = Regex("^a=ice-ufrag:(.+)$")
    static let sdpPwd = Regex("^a=ice-pwd:(.+)$")
    static let candicateUfrag = Regex(".*\\bufrag\\s+(.+?)\\s+.*")
}
