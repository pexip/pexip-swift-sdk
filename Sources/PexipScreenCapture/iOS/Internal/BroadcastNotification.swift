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

#if os(iOS)

import Foundation

enum BroadcastNotification: String {
    case senderStarted = "com.pexip.PexipScreenCapture.senderStarted"
    case senderPaused = "com.pexip.PexipScreenCapture.senderPaused"
    case senderResumed = "com.pexip.PexipScreenCapture.senderResumed"
    case senderFinished = "com.pexip.PexipScreenCapture.senderFinished"
    case receiverStarted = "com.pexip.PexipScreenCapture.receiverStarted"
    case receiverFinished = "com.pexip.PexipScreenCapture.receiverFinished"
    case presentationStolen = "com.pexip.PexipScreenCapture.presentationStolen"
    case callEnded = "com.pexip.PexipScreenCapture.callEnded"

    var cfNotificationName: CFNotificationName {
        CFNotificationName(rawValue as CFString)
    }
}

#endif
