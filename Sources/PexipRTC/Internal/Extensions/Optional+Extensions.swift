import Foundation

extension Optional {
    func valueOrNil<T>(_ type: T.Type) -> T? {
        switch self {
        case .none:
            return nil
        case .some(let value):
            if let value = value as? T {
                return value
            } else {
                preconditionFailure(
                    "Value must be an instance of \(T.self)."
                )
            }
        }
    }
}
