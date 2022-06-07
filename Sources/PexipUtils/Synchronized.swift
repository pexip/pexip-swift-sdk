import Foundation

public final class Synchronized<Value> {
    private let lock = NSLock()
    private var _value: Value

    public init(_ value: Value) {
        self._value = value
    }

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
}
