import Combine

/// Invoked when the capturing state changes.
public final class CapturingStatus: ObservableObject {
    /// True if capturing, false otherwise.
    @Published public var isCapturing: Bool

    public init(isCapturing: Bool) {
        self.isCapturing = isCapturing
    }
}

public protocol LocalMediaTrack {
    var capturingStatus: CapturingStatus { get }
    /**
     Starts the capture.
     Implementations should use ``QualityProfile/medium``
     if they support changing profiles.
     */
    func startCapture() async throws

    /// Stops the capture
    func stopCapture()
}
