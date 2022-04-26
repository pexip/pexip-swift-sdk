struct MessageFields: Encodable, Hashable {
    /// The MIME Content-Type. This must be "text/plain".
    let type = "text/plain"
    /// The contents of the message.
    let payload: String
}
