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

struct DisplayNameView: View {
    @StateObject var viewModel: DisplayNameViewModel

    var body: some View {
        MainVStack {
            Text("Welcome").font(.title)

            TextField(
                "Type your name here",
                text: $viewModel.displayName
            )
            .disableAutocorrection(true)
            .submitLabel(.next)
            .textFieldStyle(LargeTextFieldStyle())

            LargeButton(title: "Next", action: viewModel.next)
                .disabled(!viewModel.isValid)
        }
    }
}

// MARK: - Previews

struct DisplayNameView_Previews: PreviewProvider {
    static var previews: some View {
        DisplayNameView(
            viewModel: DisplayNameViewModel(onComplete: {})
        )
    }
}
