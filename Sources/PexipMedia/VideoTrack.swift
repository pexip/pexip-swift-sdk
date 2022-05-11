#if os(iOS)
import UIKit
public typealias VideoRenderer = UIView
#else
import AppKit
public typealias VideoRenderer = NSView
#endif

public protocol VideoTrack {
    func setRenderer(_ view: VideoRenderer, aspectFit: Bool)
}
