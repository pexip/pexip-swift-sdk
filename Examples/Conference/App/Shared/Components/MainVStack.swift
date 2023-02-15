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
