#if os(iOS)
import UIKit
public typealias VideoView = UIView
#elseif os(macOS)
import AppKit
public typealias VideoView = NSView
#endif

import SwiftUI

public struct PXVideoView: UIViewRepresentable {
    private let video: VideoTrackProtocol
    private let aspectFit: Bool

    public init(video: VideoTrackProtocol, aspectFit: Bool = true) {
        self.video = video
        self.aspectFit = aspectFit
    }

    public func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        Task {
            video.render(to: uiView, aspectFit: aspectFit)
        }
    }
}
