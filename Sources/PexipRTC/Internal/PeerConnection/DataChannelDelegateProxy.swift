//
// Copyright 2023 Pexip AS
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

final class DataChannelDelegateProxy: NSObject, RTCDataChannelDelegate {
    var onDataBuffer: (RTCDataBuffer) -> Void = { _ in }
    private let logger: Logger?

    // MARK: - Init

    init(logger: Logger?) {
        self.logger = logger
    }

    // MARK: - RTCDataChannelDelegate

    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        let state = DataChannelState(dataChannel.readyState)
        logger?.debug("Data channel - did change state: \(state)")
    }

    func dataChannel(
        _ dataChannel: RTCDataChannel,
        didReceiveMessageWith buffer: RTCDataBuffer
    ) {
        onDataBuffer(buffer)
    }
}
