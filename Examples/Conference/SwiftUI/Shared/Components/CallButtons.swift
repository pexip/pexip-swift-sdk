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

// MARK: - Camera

struct CameraButton: View {
    @Binding var enabled: Bool

    var body: some View {
        CircleButton(
            icon: enabled ? "video.fill" : "video.slash.fill",
            background: Material.ultraThin,
            action: { enabled.toggle() }
        )
    }
}

// MARK: - Toggle camera

struct ToggleCameraButton: View {
    let action: () -> Void

    var body: some View {
        CircleButton(
            icon: "arrow.triangle.2.circlepath",
            background: Material.ultraThin,
            action: action
        )
    }
}

// MARK: - Screen share

struct ScreenShareButton: View {
    @Binding var enabled: Bool

    var body: some View {
        CircleButton(
            icon: "display",
            background: Material.ultraThin,
            foregroundColor: enabled ? .blue : .white,
            action: { enabled.toggle() }
        )
    }
}

// MARK: - Disconnect

struct DisconnectButton: View {
    let action: () -> Void

    var body: some View {
        CircleButton(
            icon: "phone.down.fill",
            background: Color.red,
            action: action
        )
    }
}

// MARK: - Microphone

struct MicrophoneButton: View {
    @Binding var enabled: Bool

    var body: some View {
        CircleButton(
            icon: enabled ? "mic.fill" : "mic.slash.fill",
            background: Material.ultraThin,
            action: { enabled.toggle() }
        )
    }
}

// MARK: - Participants

struct ParticipantsButton: View {
    let action: () -> Void

    var body: some View {
        CircleButton(
            icon: "person.2.fill",
            background: Color.clear,
            font: .title2,
            action: action
        )
    }
}

// MARK: - Chat

struct ChatButton: View {
    let action: () -> Void

    var body: some View {
        CircleButton(
            icon: "text.bubble.fill",
            background: Color.clear,
            font: .title2,
            action: action
        )
    }
}

// MARK: - Incoming call

struct AcceptButton: View {
    let action: () -> Void

    var body: some View {
        CircleButton(
            icon: "phone.fill",
            background: Color.blue,
            action: action
        )
    }
}

typealias DeclineButton = DisconnectButton

// MARK: - Private types

private struct CircleButton<Background: ShapeStyle>: View {
    let icon: String
    let background: Background
    var foregroundColor: Color = .white
    var font: Font = .headline
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SystemIcon(
                name: icon,
                font: font,
                foregroundColor: foregroundColor
            )
            .background(background)
            .clipShape(Circle())
        }
        .shadow(radius: 4)
        .preferredColorScheme(.dark)
        .buttonStyle(PlainButtonStyle())
    }
}

struct SystemIcon: View {
    let name: String
    let font: Font
    var foregroundColor: Color = .white

    var body: some View {
        Image(systemName: name)
            .foregroundColor(foregroundColor)
            .font(font)
            .frame(width: 55, height: 55)
    }
}

// MARK: - Previews

struct CircleButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Group {
                CameraButton(enabled: .constant(true))
                CameraButton(enabled: .constant(false))
            }
            Group {
                MicrophoneButton(enabled: .constant(true))
                MicrophoneButton(enabled: .constant(false))
            }
            Group {
                ScreenShareButton(enabled: .constant(true))
                ScreenShareButton(enabled: .constant(false))
            }
            ToggleCameraButton(action: {})
            DisconnectButton(action: {})
            ChatButton(action: {})
            AcceptButton(action: {})
        }
        .background(.black)
        .previewLayout(.sizeThatFits)
    }
}
