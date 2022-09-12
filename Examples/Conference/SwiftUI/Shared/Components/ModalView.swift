import SwiftUI

struct ModalView<Content: View>: View {
    let content: Content
    let onDismiss: () -> Void
    let colorScheme: ColorScheme?
    @Environment(\.verticalSizeClass) private var vSizeClass

    // MARK: - Init

    init(
        onDismiss: @escaping () -> Void,
        colorScheme: ColorScheme?,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.onDismiss = onDismiss
        self.colorScheme = colorScheme
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            content
                .padding(.top)
            topBar
        }
        .background(
            Color(.secondarySystemBackground)
                .cornerRadius(20)
                .edgesIgnoringSafeArea(.all)
        )
        .preferredColorScheme(colorScheme)
    }

    // MARK: - Private

    private var topBar: some View {
        HStack {
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.headline)
                    .padding()
            }
        }
        .padding(vSizeClass == .compact ? .horizontal : [])
        .shadow(radius: 5)
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Previews

struct ModalView_Previews: PreviewProvider {
    static var previews: some View {
        ModalView(onDismiss: {}, colorScheme: .dark, content: {
            Color.orange
        })
    }
}
