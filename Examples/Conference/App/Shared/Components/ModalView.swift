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
