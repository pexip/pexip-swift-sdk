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

// MARK: - Protocol

/// Conference is responsible for media signaling, token refreshing
/// and handling of the conference events.
public protocol Conference: AnyObject {
    /// The object that acts as the delegate of the conference.
    var delegate: ConferenceDelegate? { get set }

    /// The publisher that publishes relevant conference events.
    var eventPublisher: AnyPublisher<ConferenceClientEvent, Never> { get }

    /// The object responsible for setting up and controlling a communication session.
    var signalingChannel: SignalingChannel { get }

    /// The full participant list of the conference.
    var roster: Roster { get }

    /// The object responsible for sending and receiving text messages in the conference.
    var chat: Chat? { get }

    /// All available conference splash screens.
    var splashScreens: [String: SplashScreen] { get }

    /// Receives conference events as they occur
    /// - Returns: False if has already subscribed to the event source
    ///            or client was disconnected, True otherwise.
    @discardableResult
    func receiveEvents() -> Bool

    /// Starts/stops receiving live caption events.
    @discardableResult
    func toggleLiveCaptions(_ show: Bool) async throws -> Bool

    /// Leaves the conference. Once left, the ``Conference`` object is no longer valid.
    func leave() async
}

// MARK: - Implementation

final class DefaultConference: Conference {
    weak var delegate: ConferenceDelegate?
    var eventPublisher: AnyPublisher<ConferenceClientEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    let signalingChannel: SignalingChannel
    let roster: Roster
    let chat: Chat?
    var splashScreens = [String: SplashScreen]()
    var isClientDisconnected: Bool { _isClientDisconnected.value }
    var status: ConferenceStatus? { _status.value }

    private typealias EventSourceTask = Task<Void, Never>

    private let tokenStore: TokenStore<ConferenceToken>
    private let connection: InfinityConnection<ConferenceEvent>
    private let splashScreenService: SplashScreenService
    private let liveCaptionsService: LiveCaptionsService
    private let logger: Logger?
    private let signalingEventSender: SignalingEventSender
    private var eventSubject = PassthroughSubject<ConferenceClientEvent, Never>()
    private var eventTask: Task<Void, Never>?
    private let decoder = JSONDecoder()
    // Skip initial `presentation_stop` event
    private let skipPresentationStop = Synchronized(true)
    private let hasRequestedSplashScreens = Synchronized(false)
    private let _status = Synchronized<ConferenceStatus?>(nil)
    private let _isClientDisconnected = Synchronized(false)

    // MARK: - Init

    init(
        connection: InfinityConnection<ConferenceEvent>,
        tokenStore: TokenStore<ConferenceToken>,
        signalingChannel: SignalingChannel & SignalingEventSender,
        roster: Roster,
        splashScreenService: SplashScreenService,
        liveCaptionsService: LiveCaptionsService,
        chat: Chat?,
        logger: Logger?
    ) {
        self.connection = connection
        self.tokenStore = tokenStore
        self.signalingChannel = signalingChannel
        self.roster = roster
        self.splashScreenService = splashScreenService
        self.liveCaptionsService = liveCaptionsService
        self.chat = chat
        self.logger = logger
        signalingEventSender = signalingChannel

        signalingChannel.data?.receiver = self

        eventTask = Task { [weak self] in
            guard let events = self?.connection.events() else {
                return
            }

            for await event in events {
                do {
                    await self?.handleEvent(try event.get())
                } catch {
                    await self?.notify(
                        .failure(FailureEvent(error: error))
                    )
                }
            }
        }

        logger?.info("Joining the conference as an API client")
    }

    deinit {
        cancelTasks()
    }

    // MARK: - Public API

    @discardableResult
    func receiveEvents() -> Bool {
        guard !isClientDisconnected else {
            return false
        }

        if connection.receiveEvents() {
            skipPresentationStop.setValue(true)
            return true
        }

        return false
    }

    @discardableResult
    func toggleLiveCaptions(_ enabled: Bool) async throws -> Bool {
        guard let status, status.liveCaptionsAvailable else {
            return false
        }

        let token = try await tokenStore.token()
        try await liveCaptionsService.toggleLiveCaptions(enabled, token: token)
        return true
    }

    func leave() async {
        logger?.info("Leaving the conference")
        cancelTasks()
        await roster.clear()
    }

    // MARK: - Private

    private func cancelTasks() {
        eventTask?.cancel()
        eventTask = nil
        connection.cancel(withTokenRelease: !isClientDisconnected)
    }

    private func loadSplashScreensIfNeeded() async {
        guard !hasRequestedSplashScreens.value else {
            return
        }

        do {
            let token = try await tokenStore.token()
            splashScreens = try await splashScreenService.splashScreens(token: token)
        } catch {
            logger?.error("Failed to load conference splash screens: \(error)")
        }

        hasRequestedSplashScreens.setValue(true)
    }

    // swiftlint:disable cyclomatic_complexity
    // swiftlint:disable function_body_length
    @MainActor
    private func handleEvent(_ event: ConferenceEvent) async {
        if case .presentationStop = event, skipPresentationStop.value {
            skipPresentationStop.setValue(false)
            return
        }

        var outputEvent: ConferenceClientEvent?

        switch event {
        case .newOffer(let message), .updateSdp(let message):
            signalingEventSender.sendEvent(.newOffer(message.sdp))
        case .newCandidate(let candidate):
            signalingEventSender.sendEvent(
                .newCandidate(candidate.candidate, mid: candidate.mid)
            )
        case .splashScreen(let event):
            if let key = event?.key {
                await loadSplashScreensIfNeeded()
                outputEvent = .splashScreen(splashScreens[key])
            } else {
                outputEvent = .splashScreen(nil)
            }
        case .conferenceUpdate(let value):
            _status.setValue(value)
            outputEvent = .conferenceUpdate(value)
        case .liveCaptions(let event):
            outputEvent = .liveCaptions(event)
        case .presentationStart(let event):
            skipPresentationStop.setValue(false)
            outputEvent = .presentationStart(event)
        case .presentationStop:
            outputEvent = .presentationStop
        case .messageReceived(let message):
            logger?.debug("Chat message received")
            await chat?.addMessage(message)
        case .participantSyncBegin:
            logger?.debug("Participant sync began")
            await roster.setSyncing(true)
        case .participantSyncEnd:
            logger?.debug("Participant sync ended")
            await roster.setSyncing(false)
        case .participantCreate(let participant):
            logger?.debug("Participant added")
            await roster.addParticipant(participant)
        case .participantUpdate(let participant):
            logger?.debug("Participant updated")
            await roster.updateParticipant(participant)
        case .participantDelete(let details):
            logger?.debug("Participant deleted")
            await roster.removeParticipant(withId: details.id)
        case .callDisconnected(let details):
            logger?.debug("Call disconnected, reason: \(details.reason)")
            outputEvent = .callDisconnected(details)
        case .clientDisconnected(let details):
            _isClientDisconnected.setValue(true)
            outputEvent = .clientDisconnected(details)
            logger?.debug("Participant disconnected, reason: \(details.reason)")
        case .peerDisconnected:
            outputEvent = .peerDisconnected
        case .refer(let event):
            outputEvent = .refer(event)
        }

        if let outputEvent {
            notify(outputEvent)
        }
    }
    // swiftlint:enable cyclomatic_complexity
    // swiftlint:enable function_body_length

    @MainActor
    private func notify(_ event: ConferenceClientEvent) {
        delegate?.conference(self, didReceiveEvent: event)
        eventSubject.send(event)
    }
}

// MARK: - DataReceiver

extension DefaultConference: DataReceiver {
    func receive(_ data: Data) async throws -> Bool {
        guard status?.directMedia == true else {
            return false
        }

        let dataMessage = try decoder.decode(DataMessage.self, from: data)

        switch dataMessage {
        case .text(let message):
            await handleEvent(.messageReceived(message))
        }

        return true
    }
}
