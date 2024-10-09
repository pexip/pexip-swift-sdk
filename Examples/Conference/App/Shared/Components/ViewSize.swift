//
// Copyright 2024 Pexip AS
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

// MARK: - View extensions

extension View {
    @ViewBuilder
    func onSizeChange(
        perform handler: @MainActor @Sendable @escaping ([CGSize]) -> Void
    ) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: SizePreferenceKey.self,
                    value: [SizePreferenceData(size: geometry.size)]
                )
            }
        )
        .onPreferenceChange(SizePreferenceKey.self) { value in
            DispatchQueue.main.async {
                handler(value.map(\.size))
            }
        }
    }
}

// MARK: - Preference keys

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: [SizePreferenceData] { [] }

    static func reduce(
        value: inout [SizePreferenceData],
        nextValue: () -> [SizePreferenceData]
    ) {
        value.append(contentsOf: nextValue())
    }
}

private struct SizePreferenceData: Identifiable, Equatable, Hashable, Sendable {
    let id = UUID()
    let size: CGSize

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
