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

import ReplayKit
import PexipScreenCapture

final class SampleHandler: RPBroadcastSampleHandler, BroadcastSampleHandlerDelegate {
    private lazy var handler: BroadcastSampleHandler = {
        let handler = BroadcastSampleHandler(appGroup: Constants.appGroup)
        handler.delegate = self
        return handler
    }()

    // MARK: - RPBroadcastSampleHandler

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        handler.broadcastStarted()
    }

    override func broadcastFinished() {
        handler.broadcastFinished()
    }

    override func processSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        with sampleBufferType: RPSampleBufferType
    ) {
        handler.processSampleBuffer(sampleBuffer, with: sampleBufferType)
    }

    // MARK: - BroadcastSampleHandlerDelegate

    func broadcastSampleHandler(
        _ handler: BroadcastSampleHandler,
        didFinishWithError error: Error
    ) {
        // Finish broadcast with user-friendly message.
        super.finishBroadcastWithError(error)
    }
}
