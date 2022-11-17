public struct MediaDevice: Identifiable {
    public let id: String
    public let name: String
    public let mediaType: MediaType
    public let direction: MediaDirection

    public init(
        id: String,
        name: String,
        mediaType: MediaType,
        direction: MediaDirection
    ) {
        self.id = id
        self.name = name
        self.mediaType = mediaType
        self.direction = direction
    }
}
