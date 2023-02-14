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

struct RegistrationView: View {
    @StateObject var viewModel: RegistrationViewModel

    // MARK: - Body

    var body: some View {
        ZStack {
            if viewModel.isRegistered {
                registrationDetails
            } else {
                form
            }
        }
        .frame(
            minWidth: 300,
            idealWidth: 400,
            maxWidth: 400,
            minHeight: 200,
            idealHeight: 200,
            maxHeight: 200
        )
    }

    // MARK: - Subviews

    private var form: some View {
        Form {
            TextField("Alias", text: $viewModel.alias)
            TextField("Username", text: $viewModel.username)
            TextField("Password", text: $viewModel.password)

            HStack {
                Spacer()
                AsyncButton(action: viewModel.register) {
                    Text("Register")
                }
                .disabled(!viewModel.isValid)
            }

            viewModel.errorMessage.map {
                Label($0, systemImage: "xmark.octagon.fill")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
        .disableAutocorrection(true)
    }

    private var registrationDetails: some View {
        VStack {
            Text("The device is registered with the alias:")
            Text(viewModel.alias)
            HStack {
                Spacer()
                AsyncButton(action: viewModel.unregister) {
                    Text("Unregister")
                }
                .disabled(!viewModel.isValid)
            }
        }
    }
}

// MARK: - Previews

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView(viewModel: RegistrationViewModel(
            service: RegistrationService(
                factory: InfinityClientFactory()
            )
        ))
    }
}
