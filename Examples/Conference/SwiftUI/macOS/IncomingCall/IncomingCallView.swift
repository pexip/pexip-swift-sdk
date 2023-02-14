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

struct IncomingCallView: View {
    @StateObject var viewModel: IncomingCallViewModel

    // MARK: - Body

    var body: some View {
        VStack {
            Spacer()
            switch viewModel.state {
            case .calling:
                content
            case .processing:
                content.overlay(overlay)
            case .error(let message):
                errorLabel(withText: message)
            }
            Spacer()
        }
        .frame(width: 250, height: 300)
        .padding()
    }

    // MARK: - Subviews

    private var content: some View {
        VStack {
            details
            buttons
        }
    }

    private var details: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.2.wave.2.fill")
                .font(.system(size: 60))
                .padding()
            Text(viewModel.details.remoteDisplayName)
                .font(.title)
                .bold()
            Text(viewModel.details.conferenceAlias)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var buttons: some View {
        HStack {
            VStack {
                DeclineButton(action: viewModel.decline)
                Text("Decline")
            }
            Spacer()
            VStack {
                AcceptButton(action: {
                    Task {
                        await viewModel.accept()
                    }
                })
                Text("Accept")
            }
        }.padding(30)
    }

    private var overlay: some View {
        ZStack {
            Color.black.opacity(0.5)
            ProgressView()
        }
    }

    private func errorLabel(withText text: String) -> some View {
        Label(text, systemImage: "xmark.octagon.fill")
            .font(.title2)
            .foregroundColor(.red)
            .padding()
    }
}

// MARK: - Previews

struct IncomingCallView_Previews: PreviewProvider {
    static var previews: some View {
        IncomingCallView(
            viewModel: .stub(state: .calling)
        )
        IncomingCallView(
            viewModel: .stub(state: .processing)
        )
        IncomingCallView(
            viewModel: .stub(state: .error("Cannot join the call. Operation failed."))
        )
    }
}

private extension IncomingCallViewModel {
    static func stub(state: State) -> IncomingCallViewModel {
        IncomingCallViewModel(
            event: .init(
                conferenceAlias: "conference@example.org",
                remoteDisplayName: "Test User",
                token: UUID().uuidString
            ),
            nodeResolver: InfinityClientFactory().nodeResolver(
                dnssec: false
            ),
            service: InfinityClientFactory().infinityService(),
            state: state,
            onAccept: { _ in },
            onDecline: {}
        )
    }
}
