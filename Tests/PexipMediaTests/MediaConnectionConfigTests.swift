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
import Combine
import PexipCore
@testable import PexipMedia

final class MediaConnectionConfigTests: XCTestCase {
    func testInit() {
        let signaling = Signaling()
        let iceServer = IceServer(
            kind: .stun,
            urls: [
                "stun:stun.l.google.com:19302",
                "stun:stun1.l.google.com:19302"
            ]
        )
        let config = MediaConnectionConfig(
            signaling: signaling,
            iceServers: [iceServer],
            dscp: true,
            presentationInMain: true
        )

        XCTAssertTrue(config.signaling is Signaling)
        XCTAssertEqual(config.iceServers, [iceServer])
        XCTAssertTrue(config.dscp)
        XCTAssertTrue(config.presentationInMain)
    }

    func testInitWithDefaults() {
        let signaling = Signaling()
        let config = MediaConnectionConfig(signaling: signaling)

        XCTAssertTrue(config.signaling is Signaling)
        XCTAssertEqual(config.iceServers, [MediaConnectionConfig.googleIceServer])
        XCTAssertFalse(config.dscp)
        XCTAssertFalse(config.presentationInMain)
    }

    func testInitWithNoStunServers() {
        let signaling = Signaling()
        let iceServer = IceServer(
            kind: .turn,
            urls: ["url1", "url2"]
        )
        let config = MediaConnectionConfig(signaling: signaling, iceServers: [iceServer])

        XCTAssertTrue(config.signaling is Signaling)
        XCTAssertEqual(config.iceServers, [iceServer] + [MediaConnectionConfig.googleIceServer])
        XCTAssertFalse(config.dscp)
        XCTAssertFalse(config.presentationInMain)
    }
}

// MARK: - Mocks

private final class Signaling: SignalingChannel {
    var callId: String?
    var iceServers = [IceServer]()
    var data: DataChannel?
    var eventPublisher: AnyPublisher<SignalingEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    private let eventSubject = PassthroughSubject<SignalingEvent, Never>()

    func sendOffer(
        callType: String,
        description: String,
        presentationInMain: Bool
    ) async throws -> String? {
        return ""
    }

    func ack(_ description: String?) async throws {}
    func addCandidate(_ candidate: String, mid: String?) async throws {}
    func muteVideo(_ muted: Bool) async throws -> Bool { true }
    func muteAudio(_ muted: Bool) async throws -> Bool { true }
    func takeFloor() async throws -> Bool { true }
    func releaseFloor() async throws -> Bool { true }
    func dtmf(signals: DTMFSignals) async throws -> Bool { false }
}
