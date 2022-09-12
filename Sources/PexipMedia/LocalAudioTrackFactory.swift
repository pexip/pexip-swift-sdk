import AVFoundation
import PexipScreenCapture

/// ``LocalAudioTrackFactory`` provides factory methods to create audio tracks.
public protocol LocalAudioTrackFactory {
    /// Creates a new local audio track.
    func createLocalAudioTrack() -> LocalAudioTrack
}
