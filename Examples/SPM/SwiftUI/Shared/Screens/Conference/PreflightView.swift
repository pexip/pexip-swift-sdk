import SwiftUI
import PexipMedia
import PexipRTC
import PexipConference

struct PreflightView: View {
    let mainLocalVideoTrack: VideoTrack?
    @Binding var cameraEnabled: Bool
    @Binding var microphoneEnabled: Bool
    let onToggleCamera: () -> Void
    let onJoin: () -> Void
    let onCancel: () -> Void
    @Environment(\.verticalSizeClass) private var sizeClass

    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            localVideoView
                .edgesIgnoringSafeArea(.all)
            MainVStack(backgroundColor: .clear, content: {
                Spacer()
                mediaButtons
                joinButton
                cancelButton
            })
            .frame(
                maxWidth: sizeClass == .compact ? 400 : .infinity,
                maxHeight: .infinity
            )
        }
    }

    private var localVideoView: some View {
        mainLocalVideoTrack.map { track in
            VideoComponent(
                track: track,
                contentMode: .fill,
                isMirrored: true
            )
        }
    }

    private var mediaButtons: some View {
        HStack(spacing: 20) {
            MicrophoneButton(enabled: $microphoneEnabled)
            CameraButton(enabled: $cameraEnabled)
            #if os(iOS)
            ToggleCameraButton(action: onToggleCamera)
            #endif
        }
        .padding(.horizontal)
    }

    private var joinButton: some View {
        LargeButton(
            title: "Join now",
            action: {
                onJoin()
            }
        )
        .padding(.top)
        .padding(.horizontal)
    }

    private var cancelButton: some View {
        Button(action: onCancel) {
            Text("Cancel")
                .foregroundColor(.white)
                .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Previews

struct PreflightView_Previews: PreviewProvider {
    static var previews: some View {
        view.previewInterfaceOrientation(.portrait)
        view.previewInterfaceOrientation(.landscapeLeft)
    }

    private static var view: some View {
        PreflightView(
            mainLocalVideoTrack: VideoTrackMock(.darkGray),
            cameraEnabled: .constant(true),
            microphoneEnabled: .constant(true),
            onToggleCamera: {},
            onJoin: {},
            onCancel: {}
        )
    }
}

final class VideoTrackMock: VideoTrack {
    #if os(iOS)
    typealias Color = UIColor
    #else
    typealias Color = NSColor
    #endif

    var aspectRatio: CGSize { QualityProfile.default.aspectRatio }
    private let backgroundColor: Color

    init(_ backgroundColor: Color) {
        self.backgroundColor = backgroundColor
    }

    func setRenderer(_ view: VideoRenderer, aspectFit: Bool) {
        #if os(iOS)
        view.layer.backgroundColor = backgroundColor.cgColor
        #else
        view.layer?.backgroundColor = backgroundColor.cgColor
        #endif
    }
}
