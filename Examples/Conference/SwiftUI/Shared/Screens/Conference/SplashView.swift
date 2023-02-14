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
import PexipInfinityClient

struct SplashView: View {
    let splashScreen: SplashScreen
    private var text: String? {
        splashScreen.elements.first(where: { $0.isTextType })?.text
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundImage
            if let text {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(text).font(.title2)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }

    private var backgroundImage: some View {
        AsyncImage(url: splashScreen.background.url) { image in
            image.resizable()
        } placeholder: {
            Color.black
        }
        .scaledToFit()
        .clipped()
    }
}

// MARK: - Previews

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView(
            splashScreen: SplashScreen(
                layoutType: "direct_media",
                background: .init(path: "test.jpg"),
                elements: [
                    .init(
                        type: "text",
                        color: 4294967295,
                        text: "Waiting for the host..."
                    )
                ]
            )
        )
    }
}
