import SwiftUI
import PexipScreenCapture

struct ScreenMediaSourcePicker: View {
    private enum Tab: Int {
        case display
        case window
    }

    @ObservedObject var viewModel: ScreenMediaSourcePickerModel
    @State private var activeTab = Tab.display

    // MARK: - Body

    var body: some View {
        VStack {
            title
            Spacer()
            if viewModel.showingErrorMessage {
                errorMessage
            } else {
                TabView(selection: $activeTab) {
                    displaysTab.tag(Tab.display)
                    windowsTab.tag(Tab.window)
                }
                .onChange(of: activeTab, perform: { tab in
                    Task {
                        switch tab {
                        case .display:
                            await viewModel.loadDisplays()
                        case .window:
                            await viewModel.loadWindows()
                        }
                    }
                })
            }
            Spacer()
            buttons
        }
        .padding()
        .frame(
            minWidth: 500,
            minHeight: 500
        )
    }

    // MARK: - Subviews

    private var title: some View {
        HStack {
            Text("Choose what to share").font(.title3)
            Spacer()
        }
    }

    private var displaysTab: some View {
        ScrollView {
            LazyVGrid(columns: columns(count: 2), spacing: 20) {
                ForEach(viewModel.displays, id: \.displayID) { display in
                    ScreenContentCell(
                        image: image(from: display)
                            .frame(idealWidth: 300, idealHeight: 168),
                        isSelected: Binding(
                            get: { viewModel.selectedVideoSource == .display(display) },
                            set: { _ in
                                viewModel.selectedVideoSource = .display(display)
                            }
                        )
                    )
                }
            }
        }
        .padding()
        .tabItem {
            Text("Entire screen")
        }
    }

    private var windowsTab: some View {
        ScrollView {
            LazyVGrid(columns: columns(count: 3), spacing: 20) {
                ForEach(viewModel.windows, id: \.windowID) { window in
                    ScreenContentCell(
                        image: image(from: window)
                            .frame(idealWidth: 200, idealHeight: 112),
                        icon: window.application?.loadAppIcon(),
                        text: window.title ?? "Untitled",
                        isSelected: Binding(
                            get: { viewModel.selectedVideoSource == .window(window) },
                            set: { _ in
                                viewModel.selectedVideoSource = .window(window)
                            }
                        )
                    )
                }
            }
        }
        .padding()
        .tabItem {
            Text("Window")
        }
    }

    @ViewBuilder
    private func image(from content: ScreenVideoContent) -> some View {
        if let cgImage = content.createImage() {
            Image(nsImage: NSImage(
                cgImage: cgImage,
                size: NSSize(width: content.width, height: content.height)
            ))
            .resizable()
            .clipped()
        } else {
            Color.gray
        }
    }

    private var errorMessage: some View {
        VStack {
            Text("Check that screen recording permissions are enabled")
            Button("Open settings", action: viewModel.openSettings)
        }
    }

    private var buttons: some View {
        HStack {
            Spacer()
            Button("Cancel", action: viewModel.cancel)
            Button("Share", action: viewModel.share)
                .disabled(viewModel.selectedVideoSource == nil)
        }
    }

    private func columns(count: Int) -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: count)
    }
}

// MARK: - Private types

private struct ScreenContentCell<T: View>: View {
    let image: T
    var icon: NSImage?
    var text: String?
    @Binding var isSelected: Bool
    @State private var isHovering = false

    var body: some View {
        VStack {
            image.scaledToFill()
            Spacer()
            text.map { text in
                HStack {
                    icon.map {
                        Image(nsImage: $0)
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
                    Text(text).lineLimit(1)
                    Spacer()
                }
            }
        }
        .onHover { isHovering in
            self.isHovering = isHovering
        }
        .onTapGesture {
            isSelected.toggle()
        }
        .padding(5)
        .border(.blue, width: isHovering || isSelected ? 1 : 0)
    }
}

// MARK: - Previews

struct ScreenMediaSourcePicker_Previews: PreviewProvider {
    static var previews: some View {
        ScreenMediaSourcePicker(
            viewModel: ScreenMediaSourcePickerModel(
                enumerator: ScreenMediaSource.createEnumerator(),
                onShare: { _ in },
                onCancel: {}
            )
        )
        .previewLayout(.fixed(width: 500, height: 500))
    }
}

private extension CGImage {
    static func image(withColor color: NSColor) -> CGImage? {
        CIContext().createCGImage(
            CIImage(color: CIColor(color: color)!),
            from: CGRect(x: 0, y: 0, width: 1, height: 1)
        )
    }
}
