#if os(iOS)

import Foundation

final class BroadcastNotificationCenter {
    static let `default` = BroadcastNotificationCenter()

    typealias Observer = () -> Void

    private let center = CFNotificationCenterGetDarwinNotifyCenter()
    private(set) var observers = [String: Observer]()

    // MARK: - Init

    private init() {}

    deinit {
        removeAllObservers()
    }

    // MARK: - Internal

    func post(_ notification: BroadcastNotification) {
        CFNotificationCenterPostNotification(
            center,
            CFNotificationName(notification.rawValue as CFString),
            nil,
            nil,
            true
        )
    }

    func addObserver(
        for notification: BroadcastNotification,
        using block: @escaping Observer
    ) {
        observers[notification.rawValue] = block

        let callback: CFNotificationCallback = { _, _, name, _, _ in
            guard let name = name?.rawValue as? String else { return }
            BroadcastNotificationCenter.default.observers[name]?()
        }

        CFNotificationCenterAddObserver(
            center,
            observerPointer(),
            callback,
            notification.rawValue as CFString,
            nil,
            .deliverImmediately
        )
    }

    func removeObserver(for notification: BroadcastNotification) {
        observers.removeValue(forKey: notification.rawValue)

        CFNotificationCenterRemoveObserver(
            center,
            observerPointer(),
            CFNotificationName(notification.rawValue as CFString),
            nil
        )
    }

    // MARK: - Private

    private func removeAllObservers() {
        CFNotificationCenterRemoveEveryObserver(
            center,
            observerPointer()
        )
    }

    private func observerPointer() -> UnsafeMutableRawPointer {
        Unmanaged.passUnretained(self).toOpaque()
    }
}

#endif
