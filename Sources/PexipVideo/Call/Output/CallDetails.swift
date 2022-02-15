struct CallDetails: Decodable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case sdp
        case id = "call_uuid"
    }

    let sdp: String
    let id: UUID
}
