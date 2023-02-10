#if os(iOS)

import Foundation

final class Synchronized<Value> {
    private let lock = NSLock()
    private var _value: Value

    init(_ value: Value) {
        self._value = value
    }

    var value: Value {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    func setValue(_ value: Value) {
        lock.lock()
        defer { lock.unlock() }
        _value = value
    }
}

#endif
