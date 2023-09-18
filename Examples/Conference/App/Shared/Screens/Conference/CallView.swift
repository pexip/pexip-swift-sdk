//
// Copyright 2022-2023 Pexip AS
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
import PexipInfinityClient
import PexipRTC

struct CallView: View {
    let mainLocalVideo: Video?
    let mainRemoteVideo: Video?
    let presentationLocalVideo: Video?
    let presentationRemoteVideo: Video?
    let splashScreen: SplashScreen?
    let presenterName: String?
    let captions: String

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
    @Environment(\.viewFactory) private var viewFactory: ViewFactory

    private var isPortrait: Bool {
        vSizeClass == .regular && hSizeClass == .compact
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            content
        }
        .onAppear(perform: {
            hideButtonsAfterDelay()
        })
    }

    private func hideButtonsAfterDelay() {
        toggleButtonsTask?.cancel()
        toggleButtonsTask = Task {
            try await Task.sleep(nanoseconds: UInt64(15 * 1_000_000_000))
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

                    selfView(geometry: geometry)

                    Spacer()
                }

                VStack(spacing: 0) {
                    Spacer()

                    if isPortrait {
                        captionsText
                    }

                    presentationView(geometry: geometry)

                    ZStack {
                        if !isPortrait {
                            HStack {
                                Spacer()
                                captionsText
                                Spacer()
                            }
                        }
                        if showingButtons {
                            bottomBar
                        }
                    }
                }
            }
        }
    }

    var mainVideoView: some View {
        ZStack(alignment: .center) {
            Color.black.edgesIgnoringSafeArea(.all)
            if let splashScreen {
                SplashView(splashScreen: splashScreen)
            } else if let video = presentationRemoteVideo {
                VideoComponent(video: video).edgesIgnoringSafeArea(.all)
            } else if let video = mainRemoteVideo {
                VideoComponent(video: video).edgesIgnoringSafeArea(.all)
            }
        }.onTapGesture {
            withAnimation {
                showingButtons.toggle()
                if showingButtons {
                    hideButtonsAfterDelay()
                }
            }
        }
    }

    func selfView(geometry: GeometryProxy) -> some View {
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
    }

    func presentationView(geometry: GeometryProxy) -> some View {
        HStack(alignment: .bottom) {
            Spacer()
            if presentationRemoteVideo != nil {
                videoView(video: mainRemoteVideo, geometry: geometry)
            } else if presentationLocalVideo != nil {
                videoView(
                    video: presentationLocalVideo,
                    supportsRotation: true,
                    geometry: geometry
                )
            } else {
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 15)
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

    @ViewBuilder var presenterNameLabel: some View {
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
            #if os(iOS)
            AudioRoutePickerView()
                .frame(width: 50, height: 50)
                .padding(.vertical)
            #endif
            viewFactory
                .settingsView()
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

    var captionsText: some View {
        Text(captions)
            .padding(20)
            .foregroundColor(.white)
            #if os(iOS)
            .font(.body)
            #else
            .font(.title)
            #endif
            .multilineTextAlignment(.center)
            .shadow(radius: 2)
    }
}

// MARK: - Helpers

private extension CallView {
    func isLandscape(geometry: GeometryProxy) -> Bool {
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
                contentMode: .fit16x9
            ),
            presentationLocalVideo: withLocalPresentation
                ? Video(
                    track: VideoTrackMock(.purple),
                    contentMode: .fit16x9
                )
                : nil,
            presentationRemoteVideo: withRemotePresentation
                ? Video(
                    track: VideoTrackMock(.purple),
                    contentMode: .fit16x9
                )
            : nil,
            splashScreen: nil,
            presenterName: withRemotePresentation ? "Presenter" : nil,
            captions: "Hello world! This is live captions.",
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
