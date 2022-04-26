import Foundation

public struct CallsFields: Encodable, Hashable {
    public enum Present: String, Encodable {
        case main
        case send
        case receive
    }

    private enum CodingKeys: String, CodingKey {
        case callType = "call_type"
        case sdp
        case present
    }

    /// "WEBRTC" for a WebRTC call
    public var callType: String
    /// Contains the SDP of the sender
    public var sdp: String
    /// Optional field. Contains "send" or "receive" to act as a
    /// presentation stream rather than a main audio/video stream
    public var present: Present?

    // MARK: - Init

    /**
     - Parameters:
        - callType: "WEBRTC" for a WebRTC call
        - sdp: Contains the SDP of the sender
        - present: Optional field. Contains "send" or "receive" to act as a
                   presentation stream rather than a main audio/video stream
     */
    public init(
        callType: String,
        sdp: String,
        present: Present? = nil
    ) {
        self.callType = callType
        self.sdp = sdp
        self.present = present
    }
}
