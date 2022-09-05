import XCTest
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
            deviceAlias: try XCTUnwrap(DeviceAlias(uri: "device@conference.com")),
            token: .randomToken()
        )
        XCTAssertTrue(registration is DefaultRegistration)
    }

    func testConference() throws {
        let conference = factory.conference(
            service: factory.infinityService(),
            node: try XCTUnwrap(URL(string: "https://example.com/conference")),
            alias: try XCTUnwrap(ConferenceAlias(uri: "conference@conference.com")),
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
            service: service
        )

        XCTAssertNotNil(chat)

        let message = UUID().uuidString
        let result = try await chat?.sendMessage(message)

        XCTAssertTrue(result == true)
        XCTAssertEqual(service.message, message)
    }

    func testChatWhenDisabled() throws {
        let token = ConferenceToken.randomToken(chatEnabled: false)
        let service = ChatServiceMock()
        let chat = factory.chat(
            token: token,
            tokenStore: TokenStore(token: token),
            service: service
        )

        XCTAssertNil(chat)
    }

    func testRoster() async throws {
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

    func participant(id: UUID) -> ParticipantService {
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
}

// swiftlint:disable unavailable_function
private struct ParticipantServiceMock: ParticipantService {
    let id: UUID

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

    func call(id: UUID) -> CallService {
        fatalError("Not implemented")
    }

    func showLiveCaptions(token: ConferenceToken) async throws {
        fatalError("Not implemented")
    }

    func hideLiveCaptions(token: ConferenceToken) async throws {
        fatalError("Not implemented")
    }
}
