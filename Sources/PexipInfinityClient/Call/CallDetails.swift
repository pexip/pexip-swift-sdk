import Foundation

public struct CallDetails: Decodable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case id = "call_uuid"
        case sdp
    }

    public let id: UUID
    public let sdp: String?

    public init(id: UUID, sdp: String?) {
        self.id = id
        self.sdp = sdp
    }
}
