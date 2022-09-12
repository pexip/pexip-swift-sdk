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
