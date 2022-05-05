import SwiftUI
import PexipRTC
import PexipConference

struct CallView: View {
    let mainLocalVideoTrack: VideoTrack?
    let mainRemoteVideoTrack: VideoTrack?
    let presentationRemoteVideoTrack: VideoTrack?
    let presenterName: String?
    @Binding var showingChat: Bool?
    @Binding var showingParticipants: Bool
    @Binding var cameraEnabled: Bool
    @Binding var microphoneEnabled: Bool
    let onToggleCamera: () -> Void
    let onDisconnect: () -> Void

    @State private var showingButtons = true
    @State private var toggleButtonsTask: Task<Void, Error>?
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass) private var vSizeClass

    // MARK: - Body

    var body: some View {
        ZStack {
            content
        }
        .onAppear(perform: {
            hideButtonsAfterDelay()
        })
        .onTapGesture {
            withAnimation {
            showingButtons.toggle()
                if showingButtons {
                    hideButtonsAfterDelay()
                }
            }
        }
    }

    private func hideButtonsAfterDelay() {
        toggleButtonsTask?.cancel()
        toggleButtonsTask = Task {
            try await Task.sleep(nanoseconds: UInt64(4 * 1_000_000_000))
            withAnimation {
                showingButtons = false
            }
        }
    }
}

// MARK: - Subviews

private extension CallView {
    var content: some View {
        ZStack {
            mainVideoView

            GeometryReader { geometry in
                VStack(spacing: 0) {
                    if showingButtons {
                        topBar
                    }

                    HStack {
                        localVideoView(geometry: geometry)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 15)

                    Spacer()
                }

                VStack(spacing: 0) {
                    Spacer()

                    if presentationRemoteVideoTrack != nil {
                        HStack {
                            Spacer()
                            smallRemoteVideoView(geometry: geometry)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 15)
                    }

                    if showingButtons {
                        bottomBar
                    }
                }
            }
        }
    }

    var mainVideoView: some View {
        ZStack(alignment: .center) {
            Color.black.edgesIgnoringSafeArea(.all)
            if let track = presentationRemoteVideoTrack {
                VideoComponent(
                    track: track,
                    contentMode: .horizontal
                ).edgesIgnoringSafeArea(.all)
            } else if let track = mainRemoteVideoTrack {
                VideoComponent(
                    track: track,
                    contentMode: .horizontal
                ).edgesIgnoringSafeArea(.all)
            }
        }
    }

    @ViewBuilder
    func smallRemoteVideoView(geometry: GeometryProxy) -> some View {
        let height = smallVideoViewSize(for: geometry)

        mainRemoteVideoTrack.map { track in
            VideoComponent(
                track: track,
                contentMode: .horizontal
            )
            .frame(height: height)
            .cornerRadius(10)
        }
    }

    @ViewBuilder
    func localVideoView(geometry: GeometryProxy) -> some View {
        let size = smallVideoViewSize(for: geometry)
        let isLandscape = isLandscape(geometry: geometry)

        mainLocalVideoTrack.map { track in
            VideoComponent(
                track: track,
                contentMode: isLandscape
                    ? .horizontal
                    : .vertical,
                isMirrored: true
            )
            .cornerRadius(10)
            .frame(
                width: isLandscape ? nil : size,
                height: isLandscape ? size : nil,
                alignment: .trailing
            )
            .shadow(radius: 2)
            .onTapGesture(perform: onToggleCamera)
        }
    }

    @ViewBuilder
    var presenterNameLabel: some View {
        presenterName.map { name in
            Text("\(name) presenting")
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .foregroundColor(.white)
                .font(.subheadline)
                .background(Color.black.opacity(0.8).cornerRadius(5))
        }
    }

    var topBar: some View {
        HStack {
            ParticipantsButton(action: {
                showingParticipants.toggle()
            })
            Spacer()
            if presentationRemoteVideoTrack != nil {
                presenterNameLabel
            }
            Spacer()
            ChatButton(action: { showingChat?.toggle() })
                .opacity(showingChat != nil ? 1 : 0)
        }
        .padding(.horizontal, 2)
        .background(
            LinearGradient.defaultGradient(startPoint: .top, endPoint: .bottom)
        )
        .transition(.opacity.animation(.easeInOut(duration: 0.3)))
    }

    var bottomBar: some View {
        HStack(spacing: 20) {
            MicrophoneButton(enabled: $microphoneEnabled)
            CameraButton(enabled: $cameraEnabled)
            Spacer()
            DisconnectButton(action: onDisconnect)
        }
        .padding([.horizontal, .bottom])
        .transition(.opacity.animation(.easeInOut(duration: 0.3)))
    }
}

// MARK: - Helpers

private extension CallView {
    func isLandscape(geometry: GeometryProxy) -> Bool {
        let isPortrait = vSizeClass == .regular && hSizeClass == .compact
        return geometry.isLandscape && !isPortrait
    }

    func smallVideoViewSize(for geometry: GeometryProxy) -> CGFloat {
        let minSize: CGFloat = 75
        let totalSize = min(geometry.size.width, geometry.size.height)
        return max(totalSize / 7, minSize)
    }
}

// MARK: - Previews

struct CallView_Previews: PreviewProvider {
    static var previews: some View {
        callView(withPresentation: false)
            .previewInterfaceOrientation(.portrait)

        VStack {
            callView(withPresentation: false)
                .frame(height: 180)
            Spacer()
        }
        .background(Color.black)
        .previewInterfaceOrientation(.portrait)

        callView(withPresentation: false)
            .previewInterfaceOrientation(.landscapeLeft)

        callView(withPresentation: true)
            .previewInterfaceOrientation(.portrait)

        callView(withPresentation: true)
            .previewInterfaceOrientation(.landscapeLeft)

        callView(withPresentation: true)
            .previewInterfaceOrientation(.landscapeRight)
    }

    private static func callView(withPresentation: Bool) -> some View {
        CallView(
            mainLocalVideoTrack: VideoTrackMock(.lightGray),
            mainRemoteVideoTrack: VideoTrackMock(.darkGray),
            presentationRemoteVideoTrack: withPresentation ? VideoTrackMock(.purple): nil,
            presenterName: withPresentation ? "Presenter" : nil,
            showingChat: .constant(false),
            showingParticipants: .constant(false),
            cameraEnabled: .constant(true),
            microphoneEnabled: .constant(true),
            onToggleCamera: {},
            onDisconnect: {}
        )
    }
}
