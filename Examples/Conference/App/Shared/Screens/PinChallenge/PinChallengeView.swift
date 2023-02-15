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

struct PinChallengeView: View {
    @StateObject var viewModel: PinChallengeViewModel

    var body: some View {
        MainVStack {
            pinInput
            viewModel.errorMessage.map {
                Label($0, systemImage: "xmark.octagon.fill")
                    .foregroundColor(.red)
            }
        }
    }

    @ViewBuilder
    private var pinInput: some View {
        Text("Welcome to the meeting, \(viewModel.displayName)!")
            .font(.title)

        SecureField("Enter your PIN here", text: $viewModel.pin)
            .textFieldStyle(LargeTextFieldStyle())
            #if os(iOS)
            .keyboardType(.numberPad)
            #endif
            .submitLabel(.join)

        if !viewModel.isPinRequired {
            Text("Or just join as a guest")
        }

        LargeButton(title: "Join", action: viewModel.submitPin)
            .disabled(!viewModel.isValid)
    }
}

// MARK: - Previews

struct PinChallengeView_Previews: PreviewProvider {
    static var previews: some View {
        PinChallengeView(
            viewModel: PinChallengeViewModel(
                tokenError: .pinRequired(guestPin: true),
                service: InfinityClientFactory()
                    .infinityService()
                    .node(url: URL(string: "https://test.example.com")!)
                    .conference(alias: ConferenceAlias(uri: "test@example.com")!),
                onComplete: { _ in }
            )
        )
    }
}
