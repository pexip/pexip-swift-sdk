struct Call: Decodable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case sdp
        case uuid = "call_uuid"
    }

    let sdp: String
    let uuid: UUID
}
