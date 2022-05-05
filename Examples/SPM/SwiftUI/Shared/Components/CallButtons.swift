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
            icon: "person.2",
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
            icon: "text.bubble",
            background: Color.clear,
            font: .title2,
            action: action
        )
    }
}

// MARK: - Private types

private struct CircleButton<Background: ShapeStyle>: View {
    let icon: String
    let background: Background
    var font: Font = .headline
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SystemIcon(name: icon, font: font)
                .background(background)
                .clipShape(Circle())
        }
        .preferredColorScheme(.dark)
        .buttonStyle(PlainButtonStyle())
    }
}

private struct SystemIcon: View {
    let name: String
    let font: Font

    var body: some View {
        Image(systemName: name)
            .foregroundColor(.white)
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
            ToggleCameraButton(action: {})
            DisconnectButton(action: {})
            ChatButton(action: {})
        }
        .background(.black)
        .previewLayout(.sizeThatFits)
    }
}
