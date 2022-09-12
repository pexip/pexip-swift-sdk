import SwiftUI

struct SettingsItemView<T: RawRepresentable>: View
where T: CaseIterable, T.RawValue == String, T: Hashable, T.AllCases: RandomAccessCollection {
    let title: String
    @Binding var selected: T

    var body: some View {
        Menu(title) {
            ForEach(T.allCases, id: \.hashValue) { option in
                button(for: option)
            }
        }
    }

    private func button(for option: T) -> some View {
        Button(action: { selected = option }) {
            HStack {
                Image(
                    systemName: option == selected
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                Text(option.rawValue)
                Spacer()
            }
        }
    }
}
