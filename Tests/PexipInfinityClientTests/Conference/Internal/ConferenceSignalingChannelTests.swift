import XCTest
@testable import PexipInfinityClient

// swiftlint:disable type_body_length
// swiftlint:disable file_length
final class ConferenceSignalingChannelTests: XCTestCase {
    private var channel: ConferenceSignalingChannel!
    private var participantService: ParticipantServiceMock!
    private var tokenStore: TokenStore<ConferenceToken>!
    private var token: ConferenceToken!
    private var roster: Roster!
    private let iceServer = IceServer(
        kind: .stun,
        urls: [
            "stun:stun.l.google.com:19302",
            "stun:stun1.l.google.com:19302"
        ]
    )
    private let sdpOffer = """
        a=ice-ufrag:ToQx\r
        a=ice-pwd:jSThfoPwGg6gKmxeTmTqz8ea\r
        a=ice-options:trickle renomination\r
        """
    private var callService: CallServiceMock { participantService.callService }

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        participantService = ParticipantServiceMock()
        roster = Roster(
            currentParticipantId: UUID().uuidString,
            currentParticipantName: "Test",
            avatarURL: { _ in nil }
        )
        token = .randomToken(role: .host)
        tokenStore = TokenStore(token: token)
        channel = ConferenceSignalingChannel(
            participantService: participantService,
            tokenStore: tokenStore,
            roster: roster,
            iceServers: [iceServer]
        )
    }

    // MARK: - Tests

    func testInit() {
        let iceServers = channel.iceServers
        XCTAssertEqual(iceServers, [iceServer])
    }

    func testSendOfferOnFirstCall() async throws {
        let expectedCallId = UUID().uuidString
        let expectedSdpAnswer = UUID().uuidString
        let sdpAnswer = try await sendOffer(
            offer: sdpOffer,
            answer: expectedSdpAnswer,
            presentationInMain: false,
            callId: expectedCallId
        )
        let pwds = channel.pwds.value
        let callId = await channel.callId

        XCTAssertEqual(sdpAnswer, expectedSdpAnswer)
        XCTAssertEqual(callId, expectedCallId)
        XCTAssertEqual(pwds, ["ToQx": "jSThfoPwGg6gKmxeTmTqz8ea"])
        XCTAssertEqual(
            participantService.callFields,
            CallsFields(callType: "WEBRTC", sdp: sdpOffer, present: nil)
        )
        XCTAssertEqual(participantService.actions, [.calls])
        XCTAssertEqual(callService.actions, [.ack])
        XCTAssertEqual(participantService.token, token)
        XCTAssertEqual(callService.token, token)
    }

    func testSendOfferOnFirstCallWithPresentationInMain() async throws {
        let expectedSdpAnswer = UUID().uuidString
        let sdpAnswer = try await sendOffer(
            offer: sdpOffer,
            answer: expectedSdpAnswer,
            presentationInMain: true
        )
        let pwds = channel.pwds.value

        XCTAssertEqual(sdpAnswer, expectedSdpAnswer)
        XCTAssertEqual(pwds, ["ToQx": "jSThfoPwGg6gKmxeTmTqz8ea"])
        XCTAssertEqual(
            participantService.callFields,
            CallsFields(callType: "WEBRTC", sdp: sdpOffer, present: .main)
        )
        XCTAssertEqual(participantService.actions, [.calls])
        XCTAssertEqual(callService.actions, [.ack])
        XCTAssertEqual(participantService.token, token)
        XCTAssertEqual(callService.token, token)
    }

    func testSendOfferOnFirstCallWithoutSdpInResponse() async throws {
        let expectedCallId = UUID().uuidString
        let sdpAnswer = try await sendOffer(
            offer: sdpOffer,
            answer: nil,
            presentationInMain: false,
            callId: expectedCallId
        )
        let pwds = channel.pwds.value
        let callId = await channel.callId

        XCTAssertNil(sdpAnswer)
        XCTAssertEqual(callId, expectedCallId)
        XCTAssertEqual(pwds, ["ToQx": "jSThfoPwGg6gKmxeTmTqz8ea"])
        XCTAssertEqual(
            participantService.callFields,
            CallsFields(callType: "WEBRTC", sdp: sdpOffer, present: nil)
        )
        XCTAssertEqual(participantService.actions, [.calls])
        XCTAssertEqual(callService.actions, [])
        XCTAssertEqual(participantService.token, token)
    }

    func testSendOfferOnFirstCallWithoutPwds() async throws {
        let sdpOffer = """
            a=ice-ufrag:ToQx\r
            """
        let expectedSdpAnswer = UUID().uuidString
        let sdpAnswer = try await sendOffer(offer: sdpOffer, answer: expectedSdpAnswer)
        let pwds = channel.pwds.value

        XCTAssertEqual(sdpAnswer, expectedSdpAnswer)
        XCTAssertTrue(pwds.isEmpty)
        XCTAssertEqual(participantService.actions, [.calls])
        XCTAssertEqual(callService.actions, [.ack])
        XCTAssertEqual(participantService.token, token)
        XCTAssertEqual(callService.token, token)
    }

    func testSendOfferOnFirstCallWithInvalidPwdsLine() async throws {
        let sdpOffer = """
            a=ice-ufrag:ToQx\r
            a=ice-options:trickle renomination\r
            """
        let expectedSdpAnswer = UUID().uuidString
        let sdpAnswer = try await sendOffer(offer: sdpOffer, answer: expectedSdpAnswer)
        let pwds = channel.pwds.value

        XCTAssertEqual(sdpAnswer, expectedSdpAnswer)
        XCTAssertTrue(pwds.isEmpty)
        XCTAssertEqual(participantService.actions, [.calls])
        XCTAssertEqual(callService.actions, [.ack])
        XCTAssertEqual(participantService.token, token)
        XCTAssertEqual(callService.token, token)
    }

    func testSendOfferOnSubsequentCalls() async throws {
        let sdpAnswer1 = UUID().uuidString
        let sdpAnswer2 = UUID().uuidString
        try await sendOffer(answer: sdpAnswer1)

        callService.results[.update] = .success(sdpAnswer2)

        let sdpAnswer = try await channel.sendOffer(
            callType: "WEBRTC",
            description: sdpOffer,
            presentationInMain: false
        )

        XCTAssertEqual(sdpAnswer, sdpAnswer2)
        XCTAssertEqual(participantService.actions, [.calls])
        XCTAssertEqual(callService.actions, [.ack, .update])
        XCTAssertEqual(participantService.token, token)
        XCTAssertEqual(callService.token, token)

        let pwds = channel.pwds.value
        XCTAssertEqual(pwds, ["ToQx": "jSThfoPwGg6gKmxeTmTqz8ea"])
    }

    func testSendOfferOnSubsequentCallsWithoutSdpInResponse() async throws {
        try await sendOffer(answer: UUID().uuidString)

        callService.results[.update] = .success(nil)

        let sdpAnswer = try await channel.sendOffer(
            callType: "WEBRTC",
            description: sdpOffer,
            presentationInMain: false
        )

        XCTAssertNil(sdpAnswer)
        XCTAssertEqual(participantService.actions, [.calls])
        XCTAssertEqual(callService.actions, [.ack, .update])
        XCTAssertEqual(participantService.token, token)
        XCTAssertEqual(callService.token, token)

        let pwds = channel.pwds.value
        XCTAssertEqual(pwds, ["ToQx": "jSThfoPwGg6gKmxeTmTqz8ea"])
    }

    func testSendAnswer() async throws {
        let answer = """
        a=ice-ufrag:ToQy\r
        a=ice-pwd:jSThfoPwGg6gKmxeYnTqz8ea\r
        a=ice-options:trickle renomination\r
        """

        try await sendOffer(answer: UUID().uuidString)
        try await channel.sendAnswer(answer)

        let pwds = channel.pwds.value
        XCTAssertEqual(pwds, ["ToQy": "jSThfoPwGg6gKmxeYnTqz8ea"])
        XCTAssertEqual(callService.actions, [.ack, .ack])
    }

    func testAddCandidate() async throws {
        try await sendOffer()
        callService.results[.newCandidate] = .success(())

        let candidate = "candidate:842163049 1 generation 0 ufrag ToQx network-id 5 "
        try await channel.addCandidate(candidate, mid: "Test")

        XCTAssertEqual(participantService.actions, [.calls])
        XCTAssertEqual(callService.actions, [.ack, .newCandidate])
        XCTAssertEqual(participantService.token, token)
        XCTAssertEqual(callService.token, token)
        XCTAssertEqual(
            callService.iceCandidate,
            IceCandidate(
                candidate: candidate,
                mid: "Test",
                ufrag: "ToQx",
                pwd: "jSThfoPwGg6gKmxeTmTqz8ea"
            )
        )
    }

    func testAddCandidateWithoutCall() async throws {
        do {
            try await channel.addCandidate("Candidate", mid: "Test")
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? ConferenceSignalingError, .callNotStarted)
            XCTAssertTrue(participantService.actions.isEmpty)
            XCTAssertTrue(callService.actions.isEmpty)
        }
    }

    func testAddCandidateWithoutPwds() async throws {
        do {
            try await sendOffer(offer: "Offer without ice pwd")
            try await channel.addCandidate("Candidate", mid: "Test")
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? ConferenceSignalingError, .pwdsMissing)
            XCTAssertEqual(participantService.actions, [.calls])
            XCTAssertEqual(callService.actions, [.ack])
            XCTAssertEqual(participantService.token, token)
            XCTAssertEqual(callService.token, token)
        }
    }

    func testAddCandidateWithoutUfrag() async throws {
        do {
            try await sendOffer()
            try await channel.addCandidate("Candidate", mid: "Test")
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? ConferenceSignalingError, .ufragMissing)
            XCTAssertEqual(participantService.actions, [.calls])
            XCTAssertEqual(callService.actions, [.ack])
            XCTAssertEqual(participantService.token, token)
            XCTAssertEqual(callService.token, token)
        }
    }

    func testDtmf() async throws {
        try await sendOffer()
        callService.results[.dtmf] = .success(true)

        let sent = try await channel.dtmf(
            signals: try XCTUnwrap(.init(rawValue: "123"))
        )

        XCTAssertTrue(sent)
        XCTAssertEqual(participantService.actions, [.calls])
        XCTAssertEqual(callService.actions, [.ack, .dtmf])
        XCTAssertEqual(participantService.token, token)
        XCTAssertEqual(callService.token, token)
    }

    func testDtmfWithoutCall() async throws {
        do {
            try await channel.dtmf(signals: try XCTUnwrap(.init(rawValue: "123")))
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? ConferenceSignalingError, .callNotStarted)
            XCTAssertTrue(participantService.actions.isEmpty)
            XCTAssertTrue(callService.actions.isEmpty)
        }
    }

    func testMuteVideoWhenMuted() async throws {
        participantService.results[.videoMuted] = .success(true)
        let result = try await channel.muteVideo(true)

        XCTAssertTrue(result)
        XCTAssertEqual(participantService.actions, [.videoMuted])
        XCTAssertEqual(participantService.token, token)
        XCTAssertTrue(callService.actions.isEmpty)
        XCTAssertNil(callService.token)
    }

    func testMuteVideoWhenUnmuted() async throws {
        participantService.results[.videoUnmuted] = .success(true)
        let result = try await channel.muteVideo(false)

        XCTAssertTrue(result)
        XCTAssertEqual(participantService.actions, [.videoUnmuted])
        XCTAssertEqual(participantService.token, token)
        XCTAssertTrue(callService.actions.isEmpty)
        XCTAssertNil(callService.token)
    }

    func testMuteAudioWhenMuted() async throws {
        participantService.results[.mute] = .success(true)
        let result = try await channel.muteAudio(true)

        XCTAssertTrue(result)
        XCTAssertEqual(participantService.actions, [.mute])
        XCTAssertEqual(participantService.token, token)
        XCTAssertTrue(callService.actions.isEmpty)
        XCTAssertNil(callService.token)
    }

    func testMuteAudioWhenUnmuted() async throws {
        participantService.results[.unmute] = .success(true)
        let result = try await channel.muteAudio(false)

        XCTAssertTrue(result)
        XCTAssertEqual(participantService.actions, [.unmute])
        XCTAssertEqual(participantService.token, token)
        XCTAssertTrue(callService.actions.isEmpty)
        XCTAssertNil(callService.token)
    }

    func testMuteAudioWhenNotHost() async throws {
        participantService.results[.mute] = .success(true)

        try await tokenStore.updateToken(.randomToken(role: .guest))
        let result = try await channel.muteAudio(false)

        XCTAssertFalse(result)
        XCTAssertTrue(participantService.actions.isEmpty)
        XCTAssertNil(participantService.token)
        XCTAssertTrue(callService.actions.isEmpty)
        XCTAssertNil(callService.token)
    }

    func testTakeFloor() async throws {
        participantService.results[.takeFloor] = .success(())

        await roster.addParticipant(
            Participant.stub(
                withId: roster.currentParticipantId,
                displayName: "Test",
                isPresenting: false
            )
        )
        let result = try await channel.takeFloor()

        XCTAssertTrue(result)
        XCTAssertEqual(participantService.actions, [.takeFloor])
        XCTAssertEqual(participantService.token, token)
        XCTAssertTrue(callService.actions.isEmpty)
        XCTAssertNil(callService.token)
    }

    func testTakeFloorWhenPresenting() async throws {
        participantService.results[.takeFloor] = .success(())

        await roster.addParticipant(
            Participant.stub(
                withId: roster.currentParticipantId,
                displayName: "Test",
                isPresenting: true
            )
        )
        let result = try await channel.takeFloor()

        XCTAssertFalse(result)
        XCTAssertTrue(participantService.actions.isEmpty)
        XCTAssertNil(participantService.token)
        XCTAssertTrue(callService.actions.isEmpty)
        XCTAssertNil(callService.token)
    }

    func testReleaseFloor() async throws {
        participantService.results[.releaseFloor] = .success(())

        await roster.addParticipant(
            Participant.stub(
                withId: roster.currentParticipantId,
                displayName: "Test",
                isPresenting: true
            )
        )
        let result = try await channel.releaseFloor()

        XCTAssertTrue(result)
        XCTAssertEqual(participantService.actions, [.releaseFloor])
        XCTAssertEqual(participantService.token, token)
        XCTAssertTrue(callService.actions.isEmpty)
        XCTAssertNil(callService.token)
    }

    func testReleaseFloorWhenNotPresenting() async throws {
        participantService.results[.releaseFloor] = .success(())

        await roster.addParticipant(
            Participant.stub(
                withId: roster.currentParticipantId,
                displayName: "Test",
                isPresenting: false
            )
        )
        let result = try await channel.releaseFloor()

        XCTAssertFalse(result)
        XCTAssertTrue(participantService.actions.isEmpty)
        XCTAssertNil(participantService.token)
        XCTAssertTrue(callService.actions.isEmpty)
        XCTAssertNil(callService.token)
    }

    // MARK: - Private

    @discardableResult
    private func sendOffer(
        offer: String? = nil,
        answer: String? = UUID().uuidString,
        presentationInMain: Bool = false,
        callId: String = UUID().uuidString
    ) async throws -> String? {
        participantService.results = [
            .calls: .success(CallDetails(id: callId, sdp: answer))
        ]
        participantService.callService.results = [
            .ack: .success(true)
        ]

        return try await channel.sendOffer(
            callType: "WEBRTC",
            description: offer ?? sdpOffer,
            presentationInMain: presentationInMain
        )
    }
}

// MARK: - Mocks

// swiftlint:disable unavailable_function
// swiftlint:disable fatal_error_message

private final class ParticipantServiceMock: ParticipantService {
    enum Action {
        case calls
        case mute
        case unmute
        case videoMuted
        case videoUnmuted
        case takeFloor
        case releaseFloor
    }

    var results = [Action: Result<Any, Error>]()
    private(set) var actions = [Action]()
    private(set) var callService = CallServiceMock()
    private(set) var token: ConferenceToken?
    private(set) var callFields: CallsFields?

    func calls(fields: CallsFields, token: ConferenceToken) async throws -> CallDetails {
        callFields = fields
        return try performAction(.calls, token: token)
    }

    func mute(token: ConferenceToken) async throws -> Bool {
        try performAction(.mute, token: token)
    }

    func unmute(token: ConferenceToken) async throws -> Bool {
        try performAction(.unmute, token: token)
    }

    func videoMuted(token: ConferenceToken) async throws -> Bool {
        try performAction(.videoMuted, token: token)
    }

    func videoUnmuted(token: ConferenceToken) async throws -> Bool {
        try performAction(.videoUnmuted, token: token)
    }

    func takeFloor(token: ConferenceToken) async throws {
        let _: Void = try performAction(.takeFloor, token: token)
    }

    func releaseFloor(token: ConferenceToken) async throws {
        let _: Void = try performAction(.releaseFloor, token: token)
    }

    func dtmf(signals: DTMFSignals, token: ConferenceToken) async throws -> Bool {
        fatalError()
    }

    func call(id: String) -> CallService { callService }
    func showLiveCaptions(token: ConferenceToken) async throws { fatalError() }
    func hideLiveCaptions(token: ConferenceToken) async throws { fatalError() }
    func avatarURL() -> URL { fatalError() }

    @discardableResult
    private func performAction<T>(_ action: Action, token: ConferenceToken) throws -> T {
        actions.append(action)
        self.token = token
        return try XCTUnwrap(results[action]?.get() as? T)
    }
}

private final class CallServiceMock: CallService {
    enum Action {
        case newCandidate
        case ack
        case update
        case dtmf
    }

    var results = [Action: Result<Any?, Error>]()
    private(set) var actions = [Action]()
    private(set) var iceCandidate: IceCandidate?
    private(set) var token: ConferenceToken?

    func newCandidate(iceCandidate: IceCandidate, token: ConferenceToken) async throws {
        self.iceCandidate = iceCandidate
        let _: Void = try performAction(.newCandidate, token: token)
    }

    func ack(sdp: String?, token: ConferenceToken) async throws -> Bool {
        try performAction(.ack, token: token)
    }

    func update(sdp: String, token: ConferenceToken) async throws -> String? {
        try performAction(.update, token: token)
    }

    func dtmf(signals: DTMFSignals, token: ConferenceToken) async throws -> Bool {
        try performAction(.dtmf, token: token)
    }

    func disconnect(token: ConferenceToken) async throws { fatalError() }

    @discardableResult
    private func performAction<T>(_ action: Action, token: ConferenceToken) throws -> T {
        actions.append(action)
        self.token = token
        return try XCTUnwrap(results[action]?.get() as? T)
    }
}
