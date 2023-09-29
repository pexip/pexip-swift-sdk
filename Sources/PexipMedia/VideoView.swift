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
    #if os(iOS)
    public typealias NativeColor = UIColor
    #else
    public typealias NativeColor = NSColor
    #endif

    public typealias SetRenderer = (
        _ view: VideoRenderer,
        _ aspectFit: Bool
    ) -> Void

    public let contentMode: VideoContentMode
    public let isMirrored: Bool
    public let isReversed: Bool
    public let backgroundColor: NativeColor
    public let cornerRadius: CGFloat
    public var aspectRatio: CGSize? {
        contentMode.aspectRatio.map {
            isReversed
                ? CGSize(width: $0.height, height: $0.width)
                : $0
        }
    }
    let setRenderer: SetRenderer

    /**
     - Parameters:
        - contentMode: Indicates whether the view should fit or fill the parent context
        - isMirrored: Indicates whether the video should be mirrored about its vertical axis
        - isReversed: Indicates whether the aspect ratio numbers should
                      get reversed (for vertical video)
        - backgroundColor: the background color of the view
        - cornerRadius: the corner radius of the view
        - setRenderer: A function that sets the given renderer
     */
    public init(
        contentMode: VideoContentMode,
        isMirrored: Bool = false,
        isReversed: Bool = false,
        backgroundColor: NativeColor = .black,
        cornerRadius: CGFloat = 0,
        setRenderer: @escaping SetRenderer
    ) {
        self.contentMode = contentMode
        self.isMirrored = isMirrored
        self.isReversed = isReversed
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.setRenderer = setRenderer
    }

    /**
     - Parameters:
        - track: The video track
        - contentMode: Indicates whether the view should fit or fill the parent context
        - isMirrored: Indicates whether the video should be mirrored about its vertical axis
        - isReversed: Indicates whether the aspect ratio numbers should
                      get reversed (for vertical video)
        - backgroundColor: the background color of the view
        - cornerRadius: the corner radius of the view
     */
    public init(
        track: VideoTrack,
        contentMode: VideoContentMode,
        isMirrored: Bool = false,
        isReversed: Bool = false,
        backgroundColor: NativeColor = .black,
        cornerRadius: CGFloat = 0
    ) {
        self.contentMode = contentMode
        self.isMirrored = isMirrored
        self.isReversed = isReversed
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.setRenderer = { view, aspectFit  in
            track.setRenderer(view, aspectFit: aspectFit)
        }
    }

    /**
     - Parameters:
        - video: The video track and content mode.
        - isMirrored: Indicates whether the video should be mirrored about its vertical axis
        - isReversed: Indicates whether the aspect ratio numbers should
                      get reversed (for vertical video)
        - backgroundColor: the background color of the view
        - cornerRadius: the corner radius of the view
     */
    public init(
        video: Video,
        isMirrored: Bool = false,
        isReversed: Bool = false,
        backgroundColor: NativeColor = .black,
        cornerRadius: CGFloat = 0
    ) {
        self.init(
            track: video.track,
            contentMode: video.contentMode,
            isMirrored: isMirrored,
            isReversed: isReversed,
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius
        )
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
            aspectFit: contentMode != .fill,
            isMirrored: isMirrored,
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            setRenderer: setRenderer
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
}

private struct VideoViewWrapper: UIViewRepresentable {
    let aspectFit: Bool
    let isMirrored: Bool
    let backgroundColor: UIColor
    let cornerRadius: CGFloat
    let setRenderer: VideoComponent.SetRenderer

    func makeUIView(context: Context) -> VideoView {
        let view = VideoView()
        setRenderer(view, aspectFit)
        view.backgroundColor = backgroundColor
        view.layer.cornerRadius = cornerRadius
        view.layer.masksToBounds = true
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
    let aspectFit: Bool
    let isMirrored: Bool
    let backgroundColor: NSColor
    let cornerRadius: CGFloat
    let setRenderer: VideoComponent.SetRenderer

    func makeNSView(context: Context) -> VideoView {
        let view = VideoView()
        setRenderer(view, aspectFit)
        view.wantsLayer = true
        view.layer?.backgroundColor = backgroundColor.cgColor
        view.layer?.cornerRadius = cornerRadius
        view.layer?.masksToBounds = true
        view.isMirrored = isMirrored
        return view
    }

    func updateNSView(_ view: VideoView, context: Context) {
        // no-op
    }
}

#endif
