import SwiftUI
import PexipMedia
import PexipRTC
import PexipConference

struct CallView: View {
    let mainLocalVideo: Video?
    let mainRemoteVideo: Video?
    let presentationLocalVideo: Video?
    let presentationRemoteVideo: Video?
    let presenterName: String?

    @Binding var showingChat: Bool?
    @Binding var showingParticipants: Bool
    @Binding var cameraEnabled: Bool
    @Binding var microphoneEnabled: Bool
    @Binding var isPresenting: Bool
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
                        videoView(
                            video: mainLocalVideo,
                            isMirrored: true,
                            supportsRotation: true,
                            geometry: geometry
                        )
                        .onTapGesture(perform: onToggleCamera)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 15)

                    Spacer()
                }

                VStack(spacing: 0) {
                    Spacer()

                    HStack {
                        Spacer()
                        if presentationRemoteVideo != nil {
                            videoView(video: mainRemoteVideo, geometry: geometry)
                        } else if presentationLocalVideo != nil {
                            videoView(
                                video: presentationLocalVideo,
                                supportsRotation: true,
                                geometry: geometry
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 15)

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
            if let video = presentationRemoteVideo {
                VideoComponent(video: video).edgesIgnoringSafeArea(.all)
            } else if let video = mainRemoteVideo {
                VideoComponent(video: video).edgesIgnoringSafeArea(.all)
            }
        }
    }

    @ViewBuilder
    func videoView(
        video: Video?,
        isMirrored: Bool = false,
        supportsRotation: Bool = false,
        geometry: GeometryProxy
    ) -> some View {
        let size = smallVideoViewSize(for: geometry)
        let isLandscape = isLandscape(geometry: geometry)
        let isReversed = supportsRotation ? !isLandscape : false

        video.map { video in
            VideoComponent(
                video: video,
                isMirrored: isMirrored,
                isReversed: isReversed
            )
            .cornerRadius(10)
            .frame(
                width: isReversed ? size : nil,
                height: isReversed ? nil : size,
                alignment: .trailing
            )
            .shadow(radius: 2)
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
            if presentationRemoteVideo != nil {
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
            ScreenShareButton(enabled: Binding(
                get: { isPresenting },
                set: { value in
                    showingButtons = false
                    isPresenting = value
                })
            )
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
        callView()
            .previewInterfaceOrientation(.portrait)

        VStack {
            callView().frame(height: 180)
            Spacer()
        }
        .background(Color.black)
        .previewInterfaceOrientation(.portrait)

        callView()
            .previewInterfaceOrientation(.landscapeLeft)

        callView(withRemotePresentation: true)
            .previewInterfaceOrientation(.portrait)

        callView(withRemotePresentation: true)
            .previewInterfaceOrientation(.landscapeLeft)

        callView(withRemotePresentation: true)
            .previewInterfaceOrientation(.landscapeRight)

        callView(withLocalPresentation: true)
            .previewInterfaceOrientation(.portrait)

        callView(withLocalPresentation: true)
            .previewInterfaceOrientation(.landscapeLeft)

        callView(withLocalPresentation: true)
            .previewInterfaceOrientation(.landscapeRight)
    }

    private static func callView(
        withRemotePresentation: Bool = false,
        withLocalPresentation: Bool = false
    ) -> some View {
        CallView(
            mainLocalVideo: Video(
                track: VideoTrackMock(.lightGray),
                qualityProfile: .high
            ),
            mainRemoteVideo: Video(
                track: VideoTrackMock(.darkGray),
                contentMode: .fit_16x9
            ),
            presentationLocalVideo: withLocalPresentation
                ? Video(
                    track: VideoTrackMock(.purple),
                    contentMode: .fit_16x9
                )
                : nil,
            presentationRemoteVideo: withRemotePresentation
                ? Video(
                    track: VideoTrackMock(.purple),
                    contentMode: .fit_16x9
                )
                : nil,
            presenterName: withRemotePresentation ? "Presenter" : nil,
            showingChat: .constant(false),
            showingParticipants: .constant(false),
            cameraEnabled: .constant(true),
            microphoneEnabled: .constant(true),
            isPresenting: .constant(false),
            onToggleCamera: {},
            onDisconnect: {}
        )
    }
}
