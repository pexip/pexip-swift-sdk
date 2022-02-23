extension LocalizedError where Self: CustomStringConvertible {
    public var errorDescription: String? {
        return description
    }
}
