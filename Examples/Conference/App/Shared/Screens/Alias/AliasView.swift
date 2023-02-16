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

struct AliasView: View {
    @StateObject var viewModel: AliasViewModel

    var body: some View {
        MainVStack {
            Text("Join conference").font(.title)

            Text("Enter a conference alias in the form of conference@example.com")

            TextField("Conference alias", text: $viewModel.text)
                #if os(iOS)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                #endif
                .disableAutocorrection(true)
                .textFieldStyle(LargeTextFieldStyle())
                .submitLabel(.search)

            LargeButton(title: "Search", action: viewModel.search)
                .disabled(!viewModel.isValid)

            viewModel.errorMessage.map {
                Label($0, systemImage: "xmark.octagon.fill")
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Previews

struct AliasView_Previews: PreviewProvider {
    static var previews: some View {
        AliasView(
            viewModel: AliasViewModel(
                nodeResolver: InfinityClientFactory().nodeResolver(
                    dnssec: false
                ),
                service: InfinityClientFactory().infinityService(),
                onComplete: { _ in }
            )
        )
    }
}
