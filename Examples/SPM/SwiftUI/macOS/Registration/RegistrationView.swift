import SwiftUI
import PexipInfinityClient

struct RegistrationView: View {
    @StateObject var viewModel: RegistrationViewModel

    // MARK: - Body

    var body: some View {
        Form {
            TextField("Alias", text: $viewModel.alias)
            TextField("Username", text: $viewModel.username)
            TextField("Password", text: $viewModel.password)
            buttons.padding(.top)
            viewModel.errorMessage.map {
                Label($0, systemImage: "xmark.octagon.fill")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
        .disableAutocorrection(true)
    }

    // MARK: - Subviews

    private var buttons: some View {
        HStack {
            Spacer()
            Button("Cancel", role: .cancel, action: viewModel.cancel)
            AsyncButton(action: viewModel.register) {
                Text("Register")
            }
            .disabled(!viewModel.isValid)
        }
    }
}

// MARK: - Previews

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView(viewModel: RegistrationViewModel(
            nodeResolver: InfinityClientFactory().nodeResolver(
                dnssec: false
            ),
            service: InfinityClientFactory().infinityService(),
            onComplete: { _ in },
            onCancel: {}
        ))
    }
}
