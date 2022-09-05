import Foundation

public final class Synchronized<Value> {
    private let lock = NSLock()
    private var _value: Value

    // MARK: - Init

    public init(_ value: Value) {
        self._value = value
    }

    // MARK: - Public

    public var value: Value {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    public func mutate(_ transform: (inout Value) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        transform(&_value)
    }

    public func setValue(_ value: Value) {
        lock.lock()
        defer { lock.unlock() }
        _value = value
    }
}
