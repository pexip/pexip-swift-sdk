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
import WebRTC
import PexipCore
@testable import PexipRTC

final class RTCConfigurationDefaultTests: XCTestCase {
    private let iceServer = IceServer(
        kind: .stun,
        urls: [
            "stun:stun.l.google.com:19302",
            "stun:stun1.l.google.com:19302"
        ]
    )

    func testDefaultConfiguration() {
        let configuration = RTCConfiguration.defaultConfiguration(
            withIceServers: [iceServer],
            dscp: true
        )

        XCTAssertEqual(configuration.iceServers.count, 1)
        XCTAssertEqual(configuration.iceServers.first?.urlStrings, iceServer.urls)
        XCTAssertEqual(configuration.sdpSemantics, .unifiedPlan)
        XCTAssertEqual(configuration.bundlePolicy, .balanced)
        XCTAssertEqual(configuration.continualGatheringPolicy, .gatherContinually)
        XCTAssertEqual(configuration.rtcpMuxPolicy, .require)
        XCTAssertEqual(configuration.tcpCandidatePolicy, .enabled)
        XCTAssertTrue(configuration.enableDscp)
        XCTAssertTrue(configuration.enableImplicitRollback)
    }
}
