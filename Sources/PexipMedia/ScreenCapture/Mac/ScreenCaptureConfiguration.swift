#if os(macOS)

import CoreMedia
import AppKit

/// An object that provides the screen capture configuration.
public struct ScreenCaptureConfiguration {
    /// The width of the output.
    public let width: Int
    /// The height of the output.
    public let height: Int
    /// The desired fps.
    public var fps: UInt = 30
    /// A Boolean value that indicates whether to scale the output
    /// to fit the configured width and height.
    public var scalesToFit = false
    /// The number of frames to keep in the queue
    public var queueDepth = 3

    var minimumFrameInterval: CMTime {
        CMTime(value: 1, timescale: CMTimeScale(fps))
    }

    var minimumFrameIntervalSeconds: Float64 {
        CMTimeGetSeconds(minimumFrameInterval)
    }

    /**
     Creates a new object that provides the screen capture configuration.
     - Parameters:
        - width: The width of the output
        - height: The height of the output
     */
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    /**
     Creates a new object that provides the screen capture configuration.
     - Parameters:
        - videoSource: The screen video source
     */
    public init(videoSource: ScreenVideoSource) {
        switch videoSource {
        case .display(let display):
            self.width = display.width
            self.height = display.height
        case .window(let window):
            self.width = window.width
            self.height = window.height
        }
    }
}

#endif
