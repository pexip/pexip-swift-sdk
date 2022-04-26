struct ResponseContainer<T>: Decodable, Hashable where T: Decodable, T: Hashable {
    /// The result field indicates if the request was successful.
    let result: T
}
