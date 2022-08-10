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
            ForEach(CameraVideoFilter.Kind.allCases, id: \.hashValue) { filter in
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
    let filter: CameraVideoFilter.Kind
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
