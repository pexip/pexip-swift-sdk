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
