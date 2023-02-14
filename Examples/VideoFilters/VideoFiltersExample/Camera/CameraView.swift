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
import PexipMedia

struct CameraView: View {
    @StateObject var viewModel: CameraViewModel

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            camera
            topBar
        }
    }

    // MARK: - Subviews

    private var camera: some View {
        VideoComponent(
            video: viewModel.video,
            isMirrored: true
        ).edgesIgnoringSafeArea(.all)
    }

    private var topBar: some View {
        VStack {
            HStack {
                Spacer()
                settings
            }
            Spacer()
        }
    }

    private var settings: some View {
        Menu {
            SettingsItemView(
                title: "Filter",
                selected: $viewModel.filterSettings
            )
            SettingsItemView(
                title: "Segmentation",
                selected: $viewModel.segmentationSettings
            )
        } label: {
            Image(systemName: "gearshape.fill").font(.title2)
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .menuIndicator(.hidden)
        .fixedSize()
        .foregroundColor(.white)
        .shadow(radius: 5)
        .padding()
    }
}

// MARK: - Previews

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView(viewModel: .init())
    }
}
