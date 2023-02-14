//
// Copyright 2022 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
        Button {
            selected = option
        } label: {
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
