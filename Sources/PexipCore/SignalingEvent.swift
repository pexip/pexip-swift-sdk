import Foundation

/// Signaling-related events
public enum SignalingEvent {
    /// New SDP offer received.
    case newOffer(String)

    /// New ICE candidate received.
    case newCandidate(_ candidate: String, mid: String?)
}
