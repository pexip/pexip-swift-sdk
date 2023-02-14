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

// MARK: - CameraFilterButton

struct SettingsView: View {
    @ObservedObject var settings: Settings

    var body: some View {
        Menu {
            cameraFilters
            liveCaptions
        } label: {
            #if os(macOS)
            Label("Settings", systemImage: "gearshape.fill")
                .shadow(radius: 4)
            #else
            SystemIcon(name: "gearshape.fill", font: .title2)
            #endif
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .menuIndicator(.hidden)
        .fixedSize()
        #if os(macOS)
        .padding(.horizontal)
        #endif
    }

    // MARK: - Subviews

    private var cameraFilters: some View {
        Menu("Camera Filters") {
            ForEach(CameraVideoFilter.allCases, id: \.hashValue) { filter in
                FilterButton(
                    filter: filter,
                    isSelected: filter == settings.cameraFilter,
                    action: {
                        settings.cameraFilter = filter
                    }
                )
            }
        }
    }

    private var liveCaptions: some View {
        MenuButton(
            title: "Live captions",
            isSelected: settings.isLiveCaptionsOn,
            action: {
                settings.showLiveCaptions.toggle()
            }
        ).disabled(!settings.isLiveCaptionsAvailable)
    }
}

// MARK: - Private types

private struct FilterButton: View {
    let filter: CameraVideoFilter
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(
                    systemName: isSelected ? "checkmark.circle.fill" : "circle"
                )
                Text(filter.rawValue)
                Spacer()
            }
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct MenuButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                }
            }
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Previews

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(settings: Settings())
    }
}
