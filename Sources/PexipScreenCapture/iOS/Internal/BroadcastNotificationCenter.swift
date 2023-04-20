//
// Copyright 2022-2023 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#if os(iOS)

import Foundation

final class BroadcastNotificationCenter {
    static let `default` = BroadcastNotificationCenter()

    typealias NotificationHandler = () -> Void

    private let center = CFNotificationCenterGetDarwinNotifyCenter()
    private(set) var observations = [Observation]()

    // MARK: - Init

    private init() {}

    // MARK: - Internal

    func post(_ notification: BroadcastNotification) {
        let name = notification.cfNotificationName
        CFNotificationCenterPostNotification(center, name, nil, nil, true)
    }

    func addObserver(
        _ observer: AnyObject,
        for notification: BroadcastNotification,
        using handler: @escaping NotificationHandler
    ) {
        let observation = Observation(
            observer: observer,
            notification: notification,
            handler: handler
        )

        if observations.contains(observation) {
            removeObserver(observer, for: notification)
        }

        observations.append(observation)

        // swiftlint:disable prefer_self_in_static_references
        let callback: CFNotificationCallback = { _, pointer, name, _, _ in
            guard let name = name?.rawValue as? String else { return }

            let observations = BroadcastNotificationCenter.default.observations

            func isIncluded(_ observation: Observation) -> Bool {
                observation.notification.rawValue == name && observation.rawPointer == pointer
            }

            for observation in observations where isIncluded(observation) {
                observation.handler()
            }
        }
        // swiftlint:enable prefer_self_in_static_references

        CFNotificationCenterAddObserver(
            center,
            observation.rawPointer,
            callback,
            observation.notification.cfNotificationName.rawValue,
            nil,
            .deliverImmediately
        )
    }

    func removeObserver(_ observer: AnyObject, for notification: BroadcastNotification? = nil) {
        func shouldRemove(_ observation: Observation) -> Bool {
            var result = observation.observer === observer

            if let notification {
                result = result && observation.notification == notification
            }

            return result
        }

        var newObservations = [Observation]()

        for observation in observations {
            if shouldRemove(observation) || observation.observer == nil {
                CFNotificationCenterRemoveObserver(
                    center,
                    observation.rawPointer,
                    observation.notification.cfNotificationName,
                    nil
                )
            } else {
                newObservations.append(observation)
            }
        }

        observations = newObservations
    }

    func removeAll() {
        for observation in observations {
            CFNotificationCenterRemoveEveryObserver(
                center,
                observation.rawPointer
            )
        }
        observations.removeAll()
    }
}

// MARK: - Observation

extension BroadcastNotificationCenter {
    final class Observation: Equatable {
        weak var observer: AnyObject?
        let notification: BroadcastNotification
        let handler: NotificationHandler

        init(
            observer: AnyObject,
            notification: BroadcastNotification,
            handler: @escaping NotificationHandler
        ) {
            self.observer = observer
            self.notification = notification
            self.handler = handler
        }

        var rawPointer: UnsafeMutableRawPointer {
            Unmanaged.passUnretained(self).toOpaque()
        }

        static func == (lhs: Observation, rhs: Observation) -> Bool {
            lhs.observer === rhs.observer && lhs.notification == rhs.notification
        }
    }
}

#endif
