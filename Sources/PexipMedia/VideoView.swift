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

import SwiftUI

// MARK: - SwiftUI

/// SwiftUI video view.
public struct VideoComponent: View {
    public let track: VideoTrack
    public let contentMode: VideoContentMode
    public let isMirrored: Bool
    public let isReversed: Bool
    public var aspectRatio: CGSize? {
        contentMode.aspectRatio.map {
            isReversed
                ? CGSize(width: $0.height, height: $0.width)
                : $0
        }
    }

    /**
     - Parameters:
        - track: The video track
        - contentMode: Indicates whether the view should fit or fill the parent context
        - isMirrored: Indicates whether the video should be mirrored about its vertical axis
        - isReversed: Indicates whether the aspect ratio numbers should
                      get reversed (for vertical video)
     */
    public init(
        track: VideoTrack,
        contentMode: VideoContentMode,
        isMirrored: Bool = false,
        isReversed: Bool = false
    ) {
        self.track = track
        self.contentMode = contentMode
        self.isMirrored = isMirrored
        self.isReversed = isReversed
    }

    /**
     - Parameters:
        - video: The video track and content mode.
        - isMirrored: Indicates whether the video should be mirrored about its vertical axis
        - isReversed: Indicates whether the aspect ratio numbers should
                      get reversed (for vertical video)
     */
    public init(
        video: Video,
        isMirrored: Bool = false,
        isReversed: Bool = false
    ) {
        self.track = video.track
        self.contentMode = video.contentMode
        self.isMirrored = isMirrored
        self.isReversed = isReversed
    }

    public var body: some View {
        if let aspectRatio {
            videoView
                .aspectRatio(
                    aspectRatio,
                    contentMode: .fit
                )
        } else {
            videoView
        }
    }

    private var videoView: some View {
        VideoViewWrapper(
            track: track,
            isMirrored: isMirrored,
            aspectFit: contentMode != .fill
        )
    }
}

// MARK: - UIKit

#if os(iOS)

public final class VideoView: UIView {
    public var isMirrored = false {
        didSet {
            transform = isMirrored ? .init(scaleX: -1, y: 1) : .identity
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .black
    }
}

private struct VideoViewWrapper: UIViewRepresentable {
    private let track: VideoTrack
    private let aspectFit: Bool
    private let isMirrored: Bool

    init(
        track: VideoTrack,
        isMirrored: Bool,
        aspectFit: Bool
    ) {
        self.track = track
        self.isMirrored = isMirrored
        self.aspectFit = aspectFit
    }

    func makeUIView(context: Context) -> VideoView {
        let view = VideoView()
        track.setRenderer(view, aspectFit: aspectFit)
        view.isMirrored = isMirrored
        return view
    }

    func updateUIView(_ view: VideoView, context: Context) {
        // no-op
    }
}

// MARK: - AppKit

#elseif os(macOS)
import AppKit

public final class VideoView: NSView {
    public var isMirrored = false {
        didSet {
            transformIfNeeded()
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = .black
    }

    private func transformIfNeeded() {
        layer?.sublayerTransform = CATransform3DIdentity

        if isMirrored {
            let translate = CATransform3DMakeTranslation(frame.width, 0, 0)
            let scale = CATransform3DMakeScale(-1, 1, 1)
            layer?.sublayerTransform = CATransform3DConcat(scale, translate)
        }
    }

    override public func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        transformIfNeeded()
    }
}

private struct VideoViewWrapper: NSViewRepresentable {
    private let track: VideoTrack
    private let aspectFit: Bool
    private let isMirrored: Bool

    init(
        track: VideoTrack,
        isMirrored: Bool,
        aspectFit: Bool
    ) {
        self.track = track
        self.isMirrored = isMirrored
        self.aspectFit = aspectFit
    }

    func makeNSView(context: Context) -> VideoView {
        let view = VideoView()
        track.setRenderer(view, aspectFit: aspectFit)
        view.isMirrored = isMirrored
        return view
    }

    func updateNSView(_ view: VideoView, context: Context) {
        // no-op
    }
}

#endif
