#if os(iOS)
import UIKit
public typealias VideoView = UIView
#elseif os(macOS)
import AppKit
public typealias VideoView = NSView
#endif

import SwiftUI

public struct PXVideoView: UIViewRepresentable {
    private let track: VideoTrackProtocol
    private let aspectFit: Bool
    private let videoMirrored: Bool

    public init(
        track: VideoTrackProtocol,
        videoMirrored: Bool = false,
        aspectFit: Bool = true
    ) {
        self.track = track
        self.videoMirrored = videoMirrored
        self.aspectFit = aspectFit
    }

    public func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        view.transform = videoMirrored ? .init(scaleX: -1, y: 1) : .identity
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        track.render(to: uiView, aspectFit: aspectFit)
    }
}
