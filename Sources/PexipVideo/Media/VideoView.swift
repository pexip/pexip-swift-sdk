import SwiftUI

// MARK: - SwiftUI

public struct VideoComponent: View {
    public enum ContentMode {
        /// Horizontal aspect ratio, e.g 16:9
        case horizontal
        /// Vertical aspect ratio, e.g 9:16
        case vertical
        /// Fill the parent context
        case fill
    }

    private let track: VideoTrackProtocol
    private let contentMode: ContentMode
    private let isMirrored: Bool
    private var aspectRatio: CGSize? {
        switch contentMode {
        case .horizontal:
            return track.aspectRatio
        case .vertical:
            return CGSize(
                width: track.aspectRatio.height,
                height: track.aspectRatio.width
            )
        case .fill:
            return nil
        }
    }

    /**
     - Parameters:
        - track: Video track
        - contentMode: Indicates whether the view should fit or fill the parent context
        - isMirrored: Indicates whether the video should be mirrored about its vertical axis
     */
    public init(
        track: VideoTrackProtocol,
        contentMode: ContentMode = .horizontal,
        isMirrored: Bool = false
    ) {
        self.track = track
        self.contentMode = contentMode
        self.isMirrored = isMirrored
    }

    public var body: some View {
        if let aspectRatio = aspectRatio {
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

    public override init(frame: CGRect) {
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
    private let track: VideoTrackProtocol
    private let aspectFit: Bool
    private let isMirrored: Bool

    init(
        track: VideoTrackProtocol,
        isMirrored: Bool,
        aspectFit: Bool
    ) {
        self.track = track
        self.isMirrored = isMirrored
        self.aspectFit = aspectFit
    }

    func makeUIView(context: Context) -> VideoView {
        let view = VideoView()
        view.isMirrored = isMirrored
        return view
    }

    func updateUIView(_ view: VideoView, context: Context) {
        track.setRenderer(view, aspectFit: aspectFit)
    }
}

// MARK: - AppKit

#elseif os(macOS)
import AppKit
public typealias VideoView = NSView
#endif
