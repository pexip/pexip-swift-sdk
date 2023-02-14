//
// Copyright 2022 Pexip AS
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
import PexipMedia

class WebRTCVideoTrack: VideoTrack {
    let rtcTrack: RTCVideoTrack
    private weak var renderer: RTCVideoRenderer?

    // MARK: - Init

    init(rtcTrack: RTCVideoTrack) {
        self.rtcTrack = rtcTrack
    }

    deinit {
        removeCurrentRenderer()
    }

    // MARK: - VideoTrack

    func setRenderer(_ view: VideoRenderer, aspectFit: Bool) {
        removeCurrentRenderer()

        #if os(iOS)
        let renderer = RTCMTLVideoView(frame: view.frame)
        renderer.videoContentMode = aspectFit ? .scaleAspectFit : .scaleAspectFill
        #else
        let renderer = RTCMTLNSVideoView(frame: view.frame)
        renderer.wantsLayer = true
        #endif
        renderer.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(renderer)

        NSLayoutConstraint.activate([
            renderer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            renderer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            renderer.topAnchor.constraint(equalTo: view.topAnchor),
            renderer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        rtcTrack.add(renderer)
        self.renderer = renderer
    }

    // MARK: - Internal

    var isEnabled: Bool {
        get {
            rtcTrack.isEnabled
        }
        set {
            rtcTrack.isEnabled = newValue
        }
    }

    func renderEmptyFrame() {
        renderer?.renderFrame(nil)
    }

    // MARK: - Private

    private func removeCurrentRenderer() {
        if let renderer {
            renderEmptyFrame()
            rtcTrack.remove(renderer)
            self.renderer = nil
        }
    }
}
