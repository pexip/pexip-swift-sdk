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

import XCTest
import PexipCore
@testable import PexipInfinityClient

final class InfinityClientFactoryTests: XCTestCase {
    private var factory: InfinityClientFactory!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        factory = InfinityClientFactory()
    }

    // MARK: - Tests

    func testInfinityService() {
        XCTAssertTrue(factory.infinityService() is DefaultInfinityService)
    }

    func testNodeResolver() {
        XCTAssertTrue(factory.nodeResolver(dnssec: false) is DefaultNodeResolver)
    }

    func testRegistration() throws {
        let registration = factory.registration(
            node: try XCTUnwrap(URL(string: "https://example.com/conference")),
            deviceAlias: "device",
            token: .randomToken()
        )
        XCTAssertTrue(registration is DefaultRegistration)
    }

    func testConference() throws {
        let conference = factory.conference(
            node: try XCTUnwrap(URL(string: "https://example.com/conference")),
            alias: "conference",
            token: .randomToken()
        )
        XCTAssertTrue(conference is DefaultConference)
    }

    func testConferenceEventSource() async throws {
        var events = [ConferenceEvent]()
        let eventService = ConferenceEventServiceMock(
            events: [.participantSyncBegin, .participantSyncEnd],
            error: InfinityTokenError.tokenExpired
        )
        let eventSource = factory.conferenceEventSource(
            tokenStore: TokenStore(token: .randomToken()),
            eventService: eventService
        )

        do {
            for try await event in eventSource.events() {
                events.append(event)
            }
        } catch {
            XCTAssertEqual(error as? InfinityTokenError, .tokenExpired)
        }

        XCTAssertEqual(events, eventService.events)
    }

    func testRegistrationEventSource() async throws {
        var events = [RegistrationEvent]()
        let eventService = RegistrationEventServiceMock(
            events: [
                .incoming(.init(
                    conferenceAlias: "Alias",
                    remoteDisplayName: "Name",
                    token: UUID().uuidString
                )),
                .incomingCancelled(.init(token: UUID().uuidString))
            ],
            error: InfinityTokenError.tokenExpired
        )
        let eventSource = factory.registrationEventSource(
            tokenStore: TokenStore(token: .randomToken()),
            eventService: eventService
        )

        do {
            for try await event in eventSource.events() {
                events.append(event)
            }
        } catch {
            XCTAssertEqual(error as? InfinityTokenError, .tokenExpired)
        }

        XCTAssertEqual(events, eventService.events)
    }

    func testChat() async throws {
        let token = ConferenceToken.randomToken(chatEnabled: true)
        let service = ChatServiceMock()
        let chat = factory.chat(
            token: token,
            tokenStore: TokenStore(token: token),
            service: service,
            signalingChannel: SignalingChannelMock()
        )

        XCTAssertNotNil(chat)

        let message = UUID().uuidString
        let result = try await chat?.sendMessage(message)

        XCTAssertTrue(result == true)
        XCTAssertEqual(service.message, message)
    }

    func testChatWithDirectMedia() async throws {
        let token = ConferenceToken.randomToken(
            chatEnabled: true,
            directMedia: true,
            dataChannelId: 1
        )
        let service = ChatServiceMock()
        let dataSender = DataSenderMock()
        let signalingChannel = SignalingChannelMock()
        signalingChannel.data?.sender = dataSender
        let chat = factory.chat(
            token: token,
            tokenStore: TokenStore(token: token),
            service: service,
            signalingChannel: signalingChannel
        )

        XCTAssertNotNil(chat)

        let message = UUID().uuidString
        let result = try await chat?.sendMessage(message)

        XCTAssertTrue(result == true)
        XCTAssertNil(service.message)
        XCTAssertNotNil(dataSender.data)
    }

    func testChatWhenDisabled() throws {
        let token = ConferenceToken.randomToken(chatEnabled: false)
        let service = ChatServiceMock()
        let chat = factory.chat(
            token: token,
            tokenStore: TokenStore(token: token),
            service: service,
            signalingChannel: SignalingChannelMock()
        )

        XCTAssertNil(chat)
    }

    func testRoster() {
        let token = ConferenceToken.randomToken()
        let service = ConferenceServiceMock()
        let roster = factory.roster(token: token, service: service)
        let avatarURL = roster.currentParticipantAvatarURL

        XCTAssertNotNil(avatarURL)
        XCTAssertEqual(
            avatarURL,
            Participant.avatarURL(id: token.participantId)
        )
    }

    func testDataChannel() {
        let token = ConferenceToken.randomToken(
            chatEnabled: true,
            directMedia: true,
            dataChannelId: 11
        )

        XCTAssertEqual(factory.dataChannel(token: token)?.id, 11)
    }

    func testDataChannelWithChatDisabled() {
        let token = ConferenceToken.randomToken(
            chatEnabled: false,
            directMedia: true,
            dataChannelId: 11
        )

        XCTAssertNil(factory.dataChannel(token: token))
    }

    func testDataChannelWithDirectMediaDisabled() {
        let token = ConferenceToken.randomToken(
            chatEnabled: true,
            directMedia: false,
            dataChannelId: 11
        )

        XCTAssertNil(factory.dataChannel(token: token))
    }

    func testDataChannelWithNoDataChannelId() {
        let token = ConferenceToken.randomToken(
            chatEnabled: true,
            directMedia: true,
            dataChannelId: nil
        )

        XCTAssertNil(factory.dataChannel(token: token))
    }
}

// MARK: - Mocks

private struct ConferenceEventServiceMock: ConferenceEventService {
    let events: [ConferenceEvent]
    let error: Error

    func events(
        token: ConferenceToken
    ) async -> AsyncThrowingStream<ConferenceEvent, Error> {
        AsyncThrowingStream { continuation in
            for event in events {
                continuation.yield(event)
            }
            continuation.finish(throwing: error)
        }
    }
}

private struct RegistrationEventServiceMock: RegistrationEventService {
    let events: [RegistrationEvent]
    let error: Error

    func events(
        token: RegistrationToken
    ) async -> AsyncThrowingStream<RegistrationEvent, Error> {
        AsyncThrowingStream { continuation in
            for event in events {
                continuation.yield(event)
            }
            continuation.finish(throwing: error)
        }
    }
}

private final class ChatServiceMock: ChatService {
    private(set) var message: String?

    func message(_ message: String, token: ConferenceToken) async throws -> Bool {
        self.message = message
        return true
    }
}

// swiftlint:disable unavailable_function
private final class ConferenceServiceMock: ConferenceService {
    func requestToken(
        fields: ConferenceTokenRequestFields,
        pin: String?
    ) async throws -> ConferenceToken {
        fatalError("Not implemented")
    }

    func requestToken(
        fields: ConferenceTokenRequestFields,
        incomingToken: String
    ) async throws -> ConferenceToken {
        fatalError("Not implemented")
    }

    func eventSource() -> ConferenceEventService {
        fatalError("Not implemented")
    }

    func participant(id: String) -> ParticipantService {
        ParticipantServiceMock(id: id)
    }

    func refreshToken(_ token: InfinityToken) async throws -> TokenRefreshResponse {
        fatalError("Not implemented")
    }

    func releaseToken(_ token: InfinityToken) async throws {
        fatalError("Not implemented")
    }

    func message(_ message: String, token: ConferenceToken) async throws -> Bool {
        fatalError("Not implemented")
    }

    func splashScreens(token: ConferenceToken) async throws -> [String: SplashScreen] {
        fatalError("Not implemented")
    }

    func backgroundURL(
        for background: SplashScreen.Background,
        token: ConferenceToken
    ) -> URL? {
        return nil
    }
}

private struct ParticipantServiceMock: ParticipantService {
    let id: String

    func calls(
        fields: CallsFields,
        token: ConferenceToken
    ) async throws -> CallDetails {
        fatalError("Not implemented")
    }

    func avatarURL() -> URL {
        Participant.avatarURL(id: id)!
    }

    func mute(token: ConferenceToken) async throws -> Bool {
        fatalError("Not implemented")
    }

    func unmute(token: ConferenceToken) async throws -> Bool {
        fatalError("Not implemented")
    }

    func videoMuted(token: ConferenceToken) async throws -> Bool {
        fatalError("Not implemented")
    }

    func videoUnmuted(token: ConferenceToken) async throws -> Bool {
        fatalError("Not implemented")
    }

    func takeFloor(token: ConferenceToken) async throws {
        fatalError("Not implemented")
    }

    func releaseFloor(token: ConferenceToken) async throws {
        fatalError("Not implemented")
    }

    func dtmf(signals: DTMFSignals, token: ConferenceToken) async throws -> Bool {
        fatalError("Not implemented")
    }

    func call(id: String) -> CallService {
        fatalError("Not implemented")
    }

    func showLiveCaptions(token: ConferenceToken) async throws {
        fatalError("Not implemented")
    }

    func hideLiveCaptions(token: ConferenceToken) async throws {
        fatalError("Not implemented")
    }
}
// swiftlint:enable unavailable_function

private final class DataSenderMock: DataSender {
    private(set) var data: Data?

    func send(_ data: Data) async throws -> Bool {
        self.data = data
        return true
    }
}
