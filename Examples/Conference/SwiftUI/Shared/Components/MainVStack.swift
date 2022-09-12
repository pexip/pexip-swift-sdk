import SwiftUI

struct MainVStack<Content: View>: View {
    var backgroundColor: Color
    let content: Content
    @Environment(\.verticalSizeClass) private var sizeClass

    init(
        backgroundColor: Color = Color(.systemBackground),
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .center) {
            backgroundColor

            VStack(spacing: 24) {
                content
            }
            .padding()
            .multilineTextAlignment(.center)
            .frame(
                maxWidth: 400,
                maxHeight: .infinity
            )
        }
        .edgesIgnoringSafeArea(.top)
    }
}
