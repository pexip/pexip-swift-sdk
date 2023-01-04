import Foundation

public struct NewOfferMessage: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case sdp
    }

    /// The remote offer sdp.
    public let sdp: String

    /// Creates a new instance of ``NewOfferMessage``
    ///
    /// - Parameters:
    ///   - sdp: The remote offer sdp
    public init(sdp: String) {
        self.sdp = sdp
    }
}

public typealias UpdateSdpMessage = NewOfferMessage
