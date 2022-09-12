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
