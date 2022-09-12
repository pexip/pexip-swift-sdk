import SwiftUI

struct LargeTextFieldStyle: TextFieldStyle {
    // swiftlint:disable identifier_name
    func _body(configuration: TextField<_Label>) -> some View {
        VStack {
            configuration
                .textFieldStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Material.ultraThin)
        )
    }
}
