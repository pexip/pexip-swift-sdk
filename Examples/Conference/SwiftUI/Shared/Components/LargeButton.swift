import SwiftUI

struct LargeButton: View {
    let title: String
    let action: () async -> Void

    var body: some View {
        AsyncButton(action: action) {
            HStack {
                Spacer()
                Text(title)
                    .foregroundColor(.white)
                Spacer()
            }
        }
        .buttonStyle(LargeButtonStyle())
        .controlSize(.large)
    }
}

private struct LargeButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(.blue, in: RoundedRectangle(cornerRadius: 10))
            .opacity(isEnabled ? configuration.isPressed ? 0.7 : 1 : 0.5)
    }
}
