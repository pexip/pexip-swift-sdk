//
// Copyright 2022-2024 Pexip AS
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

import QuartzCore

final class BroadcastDisplayLink {
    var timestamp: Double? {
        displayLink?.timestamp
    }

    private var displayLink: CADisplayLink?
    private var handler: (() -> Void)?

    // MARK: - Init

    init(fps: BroadcastFps, handler: (() -> Void)?) {
        self.handler = handler

        displayLink = CADisplayLink(
            target: self,
            selector: #selector(onDisplayLink)
        )
        displayLink?.preferredFramesPerSecond = Int(fps.value)
        displayLink?.add(to: .current, forMode: .default)
    }

    // MARK: - Internal

    func invalidate() {
        displayLink?.isPaused = true
        displayLink?.remove(from: .current, forMode: .default)
        displayLink?.invalidate()
        displayLink = nil
    }

    // MARK: - Private

    @objc
    private func onDisplayLink() {
        handler?()
    }
}

#endif
