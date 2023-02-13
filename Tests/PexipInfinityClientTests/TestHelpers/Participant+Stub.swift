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
@testable import PexipInfinityClient

extension Participant {
    static func avatarURL(id: String) -> URL? {
        URL(string: "https://vc.example.com/api/participant/\(id)/avatar.jpg")
    }

    static func stub(
        withId id: String = UUID().uuidString,
        displayName: String,
        isPresenting: Bool = false
    ) -> Participant {
        Participant(
            id: id,
            displayName: displayName,
            role: .guest,
            serviceType: .conference,
            callDirection: .inbound,
            hasMedia: true,
            isExternal: false,
            isStreamingConference: false,
            isVideoMuted: false,
            canReceivePresentation: true,
            isConnectionEncrypted: true,
            isDisconnectSupported: true,
            isFeccSupported: false,
            isAudioOnlyCall: false,
            isAudioMuted: false,
            isPresenting: isPresenting,
            isVideoCall: true,
            isMuteSupported: true,
            isTransferSupported: true
        )
    }
}
