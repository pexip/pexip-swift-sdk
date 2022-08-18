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
        VStack() {
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
