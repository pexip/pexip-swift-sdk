public actor Isolated<T> {
    public var value: T

    public init(_ value: T) {
        self.value = value
    }

    public func setValue(_ value: T) {
        self.value = value
    }
}
