import SwiftUI
import Combine
import PexipInfinityClient
import PexipMedia
import PexipRTC
import PexipConference

struct ConferenceView: View {
    @StateObject var viewModel: ConferenceViewModel
    @Environment(\.verticalSizeClass) private var sizeClass
    @Environment(\.viewFactory) private var viewFactory: ViewFactory
    #if os(macOS)
    @State private var showingScreenSharingPicker = false
    #endif

    private var showingChat: Binding<Bool?> {
        if !viewModel.hasChat {
            return .constant(nil)
        } else {
            return Binding(
                get: { [unowned viewModel] in viewModel.modal == .chat },
                set: { [unowned viewModel] value in
                    viewModel.setModal(value == true ? .chat : nil)
                }
            )
        }
    }

    private var showingParticipants: Binding<Bool> {
        Binding(
            get: { [unowned viewModel] in viewModel.modal == .participants },
            set: { [unowned viewModel] value in
                viewModel.setModal(value ? .participants : nil)
            }
        )
    }

    private var microphoneEnabled: Binding<Bool> {
        Binding(
            get: { [unowned viewModel] in viewModel.microphoneEnabled },
            set: { [unowned viewModel] value in viewModel.setMicrophoneEnabled(value) }
        )
    }

    private var cameraEnabled: Binding<Bool> {
        Binding(
            get: { viewModel.cameraEnabled },
            set: { value in viewModel.setCameraEnabled(value) }
        )
    }

    private var isPresenting: Binding<Bool> {
        Binding(
            get: { viewModel.isPresenting },
            set: { value in
                if value {
                    #if os(iOS)
                    viewModel.startPresenting()
                    #else
                    showingScreenSharingPicker = true
                    #endif
                } else {
                    viewModel.stopPresenting()
                }
            }
        )
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            switch viewModel.state {
            case .preflight:
                preflightView
            case .connecting:
                ZStack {
                    preflightView
                    Color.black
                        .opacity(0.7)
                        .edgesIgnoringSafeArea(.all)
                    Text("Joining the conference...")
                        .foregroundColor(.white)
                }
            case .connected:
                connectedView
            case .disconnected:
                Text("Call ended...")
            }
        }
    }

    private var preflightView: some View {
        PreflightView(
            mainLocalVideoTrack: viewModel.mainLocalVideo?.track,
            cameraEnabled: cameraEnabled,
            microphoneEnabled: microphoneEnabled,
            onToggleCamera: viewModel.toggleCamera,
            onJoin: viewModel.join,
            onCancel: viewModel.cancel
        )
    }

    @ViewBuilder
    private var connectedView: some View {
        GeometryReader { geometry in
            let callViewSize = callViewSize(geometry: geometry)

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    if viewModel.modal == .participants, geometry.isLandscape {
                        modalView(withGeometry: geometry, transitionEdge: .leading)
                    }
                    callView
                        .frame(
                            width: callViewSize.width,
                            height: callViewSize.height
                        )
                    if viewModel.modal == .chat, geometry.isLandscape {
                        modalView(withGeometry: geometry, transitionEdge: .trailing)
                    }
                }
                if !geometry.isLandscape {
                    modalView(withGeometry: geometry, transitionEdge: .bottom)
                }
            }
        }
    }

    private var callView: some View {
        CallView(
            mainLocalVideo: viewModel.mainLocalVideo,
            mainRemoteVideo: viewModel.mainRemoteVideo,
            presentationLocalVideo: viewModel.presentationLocalVideo,
            presentationRemoteVideo: viewModel.presentationRemoteVideo,
            presenterName: viewModel.presenterName,
            captions: viewModel.captions,
            showingChat: showingChat,
            showingParticipants: showingParticipants,
            cameraEnabled: cameraEnabled,
            microphoneEnabled: microphoneEnabled,
            isPresenting: isPresenting,
            onToggleCamera: viewModel.toggleCamera,
            onDisconnect: viewModel.leave
        )
        #if os(macOS)
        .sheet(
            isPresented: $showingScreenSharingPicker,
            content: {
                viewFactory.screenMediaSourcePicker(
                    onShare: { source in
                        showingScreenSharingPicker = false
                        viewModel.startPresenting(source)
                    },
                    onCancel: { showingScreenSharingPicker = false }
                )
            }
        )
        #endif
    }

    @ViewBuilder
    private func modalView(
        withGeometry geometry: GeometryProxy,
        transitionEdge: Edge
    ) -> some View {
        let size = modalSize(geometry: geometry)

        if let modal = viewModel.modal {
            Group {
                switch modal {
                case .chat:
                    viewModel.chatMessageStore.map {
                        viewFactory.chatView(
                            store: $0,
                            onDismiss: {
                                viewModel.setModal(nil)
                            }
                        )
                    }
                case .participants:
                    viewFactory.participantsView(
                        roster: viewModel.roster,
                        onDismiss: {
                            viewModel.setModal(nil)
                        }
                    )
                }
            }
            .frame(
                width: size.width,
                height: size.height
            )
            .transition(
                .move(edge: transitionEdge)
                .animation(.easeInOut(duration: 0.25))
            )
        }
    }

    private func callViewSize(geometry: GeometryProxy) -> CGSize {
        let modalSize = viewModel.modal != nil
            ? self.modalSize(geometry: geometry)
            : .zero
        return CGSize(
            width: geometry.isLandscape
                ? geometry.size.width - modalSize.width
                : geometry.size.width,
            height: geometry.isLandscape
                ? geometry.size.height
                : geometry.size.height - modalSize.height
        )
    }

    private func modalSize(geometry: GeometryProxy) -> CGSize {
        let aspectRatio = viewModel.remoteVideoContentMode.aspectRatio
            ?? CGSize(width: 16, height: 9)
        let videoHeight = geometry.size.width * aspectRatio.height / aspectRatio.width

        return CGSize(
            width: geometry.isLandscape
                ? geometry.size.width / 3
                : geometry.size.width,
            height: geometry.isLandscape
                ? geometry.size.height
                : geometry.size.height - videoHeight
        )
    }
}

// MARK: - Previews

struct ConferenceView_Previews: PreviewProvider {
    private static let conference = ConferenceFactory().conference(
        service: InfinityClientFactory().infinityService(),
        node: URL(string: "https://test.com")!,
        alias: ConferenceAlias(uri: "test@example.com")!,
        token: ConferenceToken(
            value: "test",
            participantId: UUID(),
            role: .guest,
            displayName: "Test",
            serviceType: "",
            conferenceName: "",
            stun: nil,
            turn: nil,
            chatEnabled: false,
            analyticsEnabled: true,
            expiresString: "1234",
            version: Version(versionId: "29", pseudoVersion: "29")
        )
    )

    static var previews: some View {
        let factory = WebRTCMediaConnectionFactory()

        ConferenceView(
            viewModel: ConferenceViewModel(
                conference: conference,
                mediaConnectionConfig: MediaConnectionConfig(
                    signaling: conference.signaling
                ),
                mediaConnectionFactory: factory,
                settings: Settings(),
                onComplete: {}
            )
        )
    }
}
