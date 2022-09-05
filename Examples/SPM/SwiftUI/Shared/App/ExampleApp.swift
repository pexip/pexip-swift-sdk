import SwiftUI

@main
struct ExampleApp: App {
    #if os(macOS)
    @State private var showingRegistration = false
    @Environment(\.viewFactory) private var viewFactory: ViewFactory
    #endif

    var body: some Scene {
        WindowGroup {
            AppCoordinator()
                #if os(macOS)
                .sheet(
                    isPresented: $showingRegistration,
                    content: {
                        viewFactory.registrationView(
                            onComplete: { token in

                            },
                            onCancel: {
                                showingRegistration = false
                            }
                        )
                        .frame(
                            minWidth: 300,
                            idealWidth: 400,
                            minHeight: 200,
                            idealHeight: 200
                        )
                    }
                )
                #endif
        }
        #if os(macOS)
        .commands {
            CommandMenu("Settings") {
                Button("Registration") {
                    showingRegistration = true
                }.keyboardShortcut("R")
            }
        }
        #endif
    }
}
