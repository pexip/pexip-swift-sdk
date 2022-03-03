// MARK: - Video

import Combine

public protocol TrackProtocol: AnyObject {
    /// The enabled state of the track.
    var isEnabled: Bool { get }
}

public protocol VideoTrackProtocol: AnyObject {
    /**
     Registers a view where all frames received on this track will be rendered.
     - Parameters:
        - view: a view where all frames received on this track will be rendered
        - aspectFit: true/false
     */
    func render(to view: VideoView, aspectFit: Bool)
}

// MARK: - Local tracks

public protocol LocalTrackProtocol: TrackProtocol {
    /// Authorization status manager.
    var capturePermission: MediaCapturePermission { get }

    /**
     Sets the enabled state of the track.
     Setting this to `true` will ask for camera permissions when unspecified.
     - Parameter enabled: The enabled state of the track
     - Returns: The enabled state of the track
     */
    @MainActor
    @discardableResult
    func setEnabled(_ enabled: Bool) async -> Bool
}

public protocol LocalVideoTrackProtocol: LocalTrackProtocol, VideoTrackProtocol {
    /// Toggles front/back camera.
    func toggleCamera()
}

public protocol LocalAudioTrackProtocol: LocalTrackProtocol {
    /// Route audio output to speaker.
    func speakerOn()

    /// Set audio routing to the default state for the current audio category.
    func speakerOff()
}
