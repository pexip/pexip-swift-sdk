//
// Copyright 2022 Pexip AS
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

import Foundation
import AppKit
import PexipInfinityClient

final class AppViewModel: ObservableObject {
    @Published var incomingCallEvent: IncomingCallEvent?

    let infinityClientFactory: InfinityClientFactory
    let registrationService: RegistrationService
    let viewFactory: ViewFactory

    init() {
        infinityClientFactory = InfinityClientFactory()
        viewFactory = ViewFactory(
            apiClientFactory: infinityClientFactory,
            settings: Settings()
        )
        registrationService = RegistrationService(
            factory: infinityClientFactory
        )
        registrationService.onCallReceived = { [weak self] event in
            self?.incomingCallEvent = event
            self?.openWindow(.incomingCall)
        }
        registrationService.onCallCancelled = { [weak self] _ in
            self?.incomingCallEvent = nil
        }

        Task {
            do {
                try await registrationService.registerFromStorage()
            } catch {
                debugPrint("Registration service: \(error)")
            }
        }
    }

    func openWindow(_ window: AppWindow) {
        if let url = URL(string: "pexipdemo://\(window.rawValue)") {
            NSWorkspace.shared.open(url)
        }
    }
}
