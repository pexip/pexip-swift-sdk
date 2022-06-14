import Combine

// MARK: - CapturingStatus

/// Invoked when the capturing state changes.
public final class CapturingStatus: ObservableObject {
    /// True if capturing, false otherwise.
    @Published public var isCapturing: Bool

    public init(isCapturing: Bool) {
        self.isCapturing = isCapturing
    }
}

// MARK: - LocalMediaTrack

public protocol LocalMediaTrack {
    var capturingStatus: CapturingStatus { get }

    /// Starts the capture.
    /// Implementations should use default ``QualityProfile``
    /// if they support changing profiles.
    func startCapture() async throws

    /// Stops the capture
    func stopCapture()
}
