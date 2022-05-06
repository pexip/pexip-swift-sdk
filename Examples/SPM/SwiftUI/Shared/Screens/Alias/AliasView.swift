import SwiftUI
import PexipInfinityClient
import PexipConference

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
