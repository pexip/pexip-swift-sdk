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
import PexipRTC

struct PreflightView: View {
    let mainLocalVideoTrack: VideoTrack?
    @Binding var cameraEnabled: Bool
    @Binding var microphoneEnabled: Bool
    let onToggleCamera: () -> Void
    let onJoin: () -> Void
    let onCancel: () -> Void
    @Environment(\.verticalSizeClass) private var sizeClass
    @Environment(\.viewFactory) private var viewFactory: ViewFactory

    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            localVideoView
                .edgesIgnoringSafeArea(.all)
            #if os(macOS)
            VStack {
                topBar.padding(.horizontal)
                Spacer()
            }
            #endif

            MainVStack(backgroundColor: .clear, content: {
                #if os(iOS)
                topBar
                #endif
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

    private var topBar: some View {
        HStack(spacing: 4) {
            Spacer()
            #if os(iOS)
            AudioRoutePickerView()
                .frame(width: 50, height: 50)
                .padding(.vertical)
            #endif
            viewFactory.settingsView()
        }
        .padding(.top)
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
                .padding(5)
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
