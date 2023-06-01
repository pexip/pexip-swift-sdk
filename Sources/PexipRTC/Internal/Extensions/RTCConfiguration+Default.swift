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

import WebRTC
import PexipCore

extension RTCConfiguration {
    static func defaultConfiguration(
        withIceServers iceServers: [IceServer],
        dscp: Bool
    ) -> RTCConfiguration {
        let configuration = RTCConfiguration()
        configuration.iceServers = iceServers.map {
            RTCIceServer(
                urlStrings: $0.urls,
                username: $0.username,
                credential: $0.password
            )
        }
        configuration.bundlePolicy = .balanced
        configuration.sdpSemantics = .unifiedPlan
        configuration.enableDscp = dscp
        configuration.continualGatheringPolicy = .gatherContinually
        configuration.enableImplicitRollback = true
        return configuration
    }
}
