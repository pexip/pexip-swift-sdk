import Foundation

public struct CallDetails: Decodable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case id = "call_uuid"
        case sdp
    }

    public let id: String
    public let sdp: String?

    public init(id: String, sdp: String?) {
        self.id = id
        self.sdp = sdp
    }
}
