import PexipMedia
import PexipInfinityClient
import PexipUtils

actor ConferenceSignaling: MediaConnectionSignaling {
    private typealias CallDetailsTask = Task<CallDetails, Error>

    private let participantService: ParticipantService
    private let tokenStore: TokenStore
    private let logger: Logger?
    private var isConnected = false
    private var pwds = [String: String]()
    private var callsRequestTask: CallDetailsTask?

    // MARK: - Init

    init(
        participantService: ParticipantService,
        tokenStore: TokenStore,
        logger: Logger?
    ) {
        self.participantService = participantService
        self.tokenStore = tokenStore
        self.logger = logger
    }

    deinit {
        callsRequestTask?.cancel()
    }

    // MARK: - MediaConnectionSignaling

    func onOffer(
        callType: String,
        description: String,
        presentationType: PresentationType?
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
                        present: presentationType?.presentField
                    ),
                    token: token
                )
            }
            return try await callsRequestTask!.value.sdp
        }
    }

    func onCandidate(candidate: String, mid: String?) async throws {
        guard let callService = try await callService else {
            logger?.warn("Tried to send a new ICE candidate before starting a call")
            return
        }

        guard !pwds.isEmpty else {
            logger?.warn("ConferenceSignaling.onCandidate - pwds are not set")
            return
        }

        guard let ufrag = candidateUfrag(from: candidate) else {
            logger?.warn("ConferenceSignaling.onCandidate - ufrag are not set")
            return
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

    func onConnected() async throws {
        guard let callService = try await callService else {
            logger?.warn("Tried to ack before starting a call")
            return
        }
        isConnected = try await callService.ack(token: await tokenStore.token())
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

private extension Regex {
    static let sdpUfrag = Regex("^a=ice-ufrag:(.+)$")
    static let sdpPwd = Regex("^a=ice-pwd:(.+)$")
    static let candicateUfrag = Regex(".*\\bufrag\\s+(.+?)\\s+.*")
}

private extension PresentationType {
    var presentField: CallsFields.Present? {
        switch self {
        case .inMix:
            return .main
        case .receive:
            return .receive
        }
    }
}
