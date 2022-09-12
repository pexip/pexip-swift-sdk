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
                    node: incomingCall.node,
                    alias: incomingCall.alias,
                    token: incomingCall.token,
                    onComplete: {
                        self.incomingCall = nil
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
