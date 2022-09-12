import SwiftUI
import PexipInfinityClient

struct AppCoordinator: View {
    @State private var screen: Screen = .displayName
    @State private var reversedTransitions = false
    @Environment(\.viewFactory) private var viewFactory: ViewFactory

    private var transition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: reversedTransitions ? .leading : .trailing),
            removal: .move(edge: reversedTransitions ? .trailing : .leading)
        )
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            currentScreen
                .transition(transition)
                .animation(.default, value: screen)
        }
        #if os(macOS)
        .frame(
            minWidth: 800,
            idealWidth: 900,
            minHeight: 600,
            idealHeight: 650
        )
        #endif
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch screen {
        case .displayName:
            viewFactory.displayNameView(onComplete: {
                push(.alias)
            })
        case .alias:
            NavigationStep(onBack: {
                pop(to: .displayName)
            }, content: {
                viewFactory.aliasView(
                    onComplete: { output in
                        switch output.token {
                        case .success(let token):
                            push(.conference(
                                alias: output.alias,
                                node: output.node,
                                token: token
                            ))
                        case .failure(let error):
                            push(.pinChallenge(
                                alias: output.alias,
                                node: output.node,
                                tokenError: error
                            ))
                        }
                    }
                )
            })
        case let .pinChallenge(alias, node, tokenError):
            NavigationStep(onBack: { pop(to: .alias) }, content: {
                viewFactory.pinChallengeView(
                    node: node,
                    alias: alias,
                    tokenError: tokenError,
                    onComplete: { token in
                        push(.conference(
                            alias: alias,
                            node: node,
                            token: token
                        ))
                    }
                )
            })
        case let .conference(alias, node, token):
            viewFactory.conferenceView(
                node: node,
                alias: alias,
                token: token,
                onComplete: {
                    pop(to: .alias)
                }
            )
        }
    }

    private func pop(to screen: Screen) {
        self.reversedTransitions = true
        self.screen = screen
    }

    private func push(_ screen: Screen) {
        self.reversedTransitions = false
        self.screen = screen
    }
}

private struct NavigationStep<Content>: View where Content: View {
    var onBack: (() -> Void)?
    let content: () -> Content

    var body: some View {
        ZStack {
            content()
            if let onBack = onBack {
                VStack {
                    HStack {
                        backButton(action: onBack)
                        Spacer()
                    }
                    Spacer()
                }
                .padding()
            }
        }
    }

    private func backButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: "chevron.backward")
                Text("Back")
            }
        }
    }
}
