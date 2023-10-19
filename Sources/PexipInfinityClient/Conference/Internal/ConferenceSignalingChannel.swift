//
// Copyright 2022-2023 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import Combine
import PexipCore

// MARK: - Protocols

protocol SignalingEventSender {
    func sendEvent(_ event: SignalingEvent)
}

// MARK: - Implementation

final class ConferenceSignalingChannel: SignalingChannel, SignalingEventSender {
    private typealias CallDetailsTask = Task<CallDetails, Error>

    var eventPublisher: AnyPublisher<SignalingEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    let iceServers: [IceServer]
    let data: DataChannel?

    private(set) var pwds = Synchronized<[String: String]>([:])

    var callId: String? {
        get async {
            try? await callsRequestTask.value?.value.id
        }
    }

    private let participantService: ParticipantService
    private let tokenStore: TokenStore<ConferenceToken>
    private let roster: Roster
    private let logger: Logger?
    private var callsRequestTask = Synchronized<CallDetailsTask?>(nil)
    private let eventSubject = PassthroughSubject<SignalingEvent, Never>()

    // MARK: - Init

    init(
        participantService: ParticipantService,
        tokenStore: TokenStore<ConferenceToken>,
        roster: Roster,
        iceServers: [IceServer],
        data: DataChannel? = nil,
        logger: Logger? = nil
    ) {
        self.participantService = participantService
        self.tokenStore = tokenStore
        self.roster = roster
        self.iceServers = iceServers
        self.data = data
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

        pwds.setValue(sdpPwds(from: description))

        callsRequestTask.setValue(CallDetailsTask {
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
        })

        var remoteDescription = try await callsRequestTask.value!.value.sdp
        remoteDescription = remoteDescription?.isEmpty == true
            ? nil
            : remoteDescription

        return remoteDescription
    }

    func ack( _ description: String?) async throws {
        guard let callService = try await callService else {
            logger?.warn("Tried to ack before starting a call")
            return
        }

        if let description {
            pwds.setValue(sdpPwds(from: description))
        }

        _ = try await callService.ack(
            sdp: description,
            token: await tokenStore.token()
        )
    }

    func addCandidate(_ candidate: String, mid: String?) async throws {
        guard let callService = try await callService else {
            logger?.warn("Tried to send a new ICE candidate before starting a call")
            throw ConferenceSignalingError.callNotStarted
        }

        guard !pwds.value.isEmpty else {
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
                pwd: pwds.value[ufrag]
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

    // MARK: - Internal

    func sendEvent(_ event: SignalingEvent) {
        eventSubject.send(event)
    }

    // MARK: - Private

    private var callService: CallService? {
        get async throws {
            guard let callDetailsTask = callsRequestTask.value else {
                return nil
            }
            return try await participantService.call(id: callDetailsTask.value.id)
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

private extension PexipCore.Regex {
    static let sdpUfrag = Regex("^a=ice-ufrag:(.+)$")
    static let sdpPwd = Regex("^a=ice-pwd:(.+)$")
    static let candicateUfrag = Regex(".*\\bufrag\\s+(.+?)\\s+.*")
}
