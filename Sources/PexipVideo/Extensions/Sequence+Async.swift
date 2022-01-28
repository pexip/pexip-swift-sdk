extension Sequence {
    func asyncFirst(
        where predicate: (Element) async throws -> Bool
    ) async rethrows -> Element? {
        for element in self {
            if try await predicate(element) {
                return element
            }
        }

        return nil
    }
}
