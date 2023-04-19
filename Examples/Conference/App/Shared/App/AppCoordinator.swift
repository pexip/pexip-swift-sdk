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

    @ViewBuilder private var currentScreen: some View {
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
                                ConferenceDetails(
                                    node: output.node,
                                    alias: output.alias,
                                    token: token
                                ),
                                preflight: true
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
                            ConferenceDetails(node: node, alias: alias, token: token),
                            preflight: true
                        ))
                    }
                )
            })
        case let .conference(details, preflight):
            viewFactory.conferenceView(
                details: details,
                preflight: preflight,
                onComplete: { completion in
                    switch completion {
                    case .exit:
                        pop(to: .alias)
                    case .transfer(let details):
                        push(.conference(details, preflight: false))
                    }
                }
            ).id(details.id)
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
