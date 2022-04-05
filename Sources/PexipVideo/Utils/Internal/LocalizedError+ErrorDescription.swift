public extension LocalizedError where Self: CustomStringConvertible {
    var errorDescription: String? {
        return description
    }
}
