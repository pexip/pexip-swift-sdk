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

/// Conference-related events important for the consumer of the SDK.
@frozen
public enum ConferenceClientEvent: Hashable {
    /// New conference splash screen event received.
    case splashScreen(SplashScreen?)

    /// Conference properties have been updated.
    case conferenceUpdate(ConferenceStatus)

    /// New live captions event received.
    case liveCaptions(LiveCaptions)

    /// Marks the start of a presentation,
    /// and includes the information on which participant is presenting.
    case presentationStart(PresentationStartEvent)

    /// The presentation has finished.
    case presentationStop

    /// Another peer disconnected from the direct media call.
    case peerDisconnected

    /// The participant has been transfered to another call.
    case refer(ReferEvent)

    /// Sent when a child call has been disconnected.
    case callDisconnected(CallDisconnectEvent)

    /// Sent when the participant is being disconnected from the Pexip side.
    case clientDisconnected(ClientDisconnectEvent)

    /// Unhandled error occured during the conference call.
    case failure(FailureEvent)
}
