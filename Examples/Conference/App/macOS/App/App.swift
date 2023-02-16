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

import SwiftUI
import PexipInfinityClient

@main
struct App: SwiftUI.App {
    enum MenuBarItem: Int, Identifiable {
        var id: Int { rawValue }

        case displayName
        case registration
    }

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = AppViewModel()
    @State private var incomingCall: IncomingCall?

    // MARK: - Body

    var body: some Scene {
        WindowGroup("Main") {
            if let incomingCall = incomingCall {
                viewModel.viewFactory.conferenceView(
                    details: incomingCall,
                    preflight: false,
                    onComplete: { completion in
                        switch completion {
                        case .exit:
                            self.incomingCall = nil
                        case .transfer(let newCall):
                            self.incomingCall = newCall
                        }
                    })
            } else {
                AppCoordinator()
                    .environment(\.viewFactory, viewModel.viewFactory)
            }
        }
        .commands {
            CommandGroup(replacing: .newItem, addition: { })

            CommandMenu("Settings") {
                Button("Registration") {
                    viewModel.openWindow(.registration)
                }.keyboardShortcut("R")

                Button("Display Name") {
                    viewModel.openWindow(.displayName)
                }.keyboardShortcut("N")
            }
        }
        .handlesExternalEvents(
            matching: Set([AppWindow.main.rawValue])
        )

        WindowGroup("DisplayName") {
            viewModel.viewFactory.displayNameView(onComplete: {
            })
        }
        .handlesExternalEvents(
            matching: Set([AppWindow.displayName.rawValue])
        )

        WindowGroup("Registration") {
            viewModel.viewFactory.registrationView(
                service: viewModel.registrationService
            )
        }
        .handlesExternalEvents(
            matching: Set([AppWindow.registration.rawValue])
        )

        WindowGroup("IncomingCall") {
            viewModel.incomingCallEvent.map {
                viewModel.viewFactory.incomingCallView(
                    event: $0,
                    onAccept: { incomingCall in
                        viewModel.incomingCallEvent = nil
                        NSApplication.shared.keyWindow?.close()
                        self.incomingCall = incomingCall
                        NSApp.activate(ignoringOtherApps: true)
                    },
                    onDecline: {
                        viewModel.incomingCallEvent = nil
                        NSApplication.shared.keyWindow?.close()
                    }
                )
            }
        }
        .handlesExternalEvents(
            matching: Set([AppWindow.incomingCall.rawValue])
        )
    }
}
