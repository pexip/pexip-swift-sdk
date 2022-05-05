import SwiftUI
import PexipConference

struct ChatView: View {
    @StateObject var viewModel: ChatViewModel
    let onDismiss: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.verticalSizeClass) private var vSizeClass

    var body: some View {
        ModalView(onDismiss: onDismiss, colorScheme: .dark, content: {
            VStack(spacing: 0) {
                list
                Divider().edgesIgnoringSafeArea(.all)
                textBox
            }
        })
    }

    private var list: some View {
        List(viewModel.messages, id: \.hashValue) { message in
            ChatMessageCell(message: message)
        }
        .listStyle(.plain)
        .onTapGesture {
            isTextFieldFocused = false
        }
    }

    private var textBox: some View {
        TextBoxView(
            text: $viewModel.text,
            showingErrorBadge: viewModel.showingErrorBadge,
            action: viewModel.send
        )
        .focused($isTextFieldFocused)
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Subviews

private struct ChatMessageCell: View {
    let message: ChatViewModel.Message

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(message.title)
                    .font(.headline)
                    .bold()
                Text(message.timeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            Text(message.text)
                .font(.body)
        }
        .multilineTextAlignment(.leading)
        #if os(iOS)
        .listRowSeparator(.hidden)
        #endif
        .listRowBackground(Color(.secondarySystemBackground))
        .preferredColorScheme(.dark)
    }
}

private struct TextBoxView: View {
    @Binding var text: String
    let showingErrorBadge: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            TextField("Text message", text: $text)
                .textFieldStyle(LargeTextFieldStyle())
                .disableAutocorrection(true)

            Button(action: action, label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .padding()
                    .overlay(errorBadge)
            })
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.leading)
        .padding(.vertical, 5)
        .preferredColorScheme(.dark)
    }

    private var errorBadge: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.footnote)
                        .opacity(showingErrorBadge ? 1 : 0)
                }
                Spacer()
            }
            .padding(5)
        }
    }
}

// MARK: - Previews

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            chatView.frame(height: 500)
        }
        .background(Color(.white))
        .previewInterfaceOrientation(.portrait)

        HStack {
            Spacer()
            chatView.frame(width: 350)
        }
        .background(Color(.white))
        .previewInterfaceOrientation(.landscapeLeft)

        ChatMessageCell(
            message: .init(title: "User Name", text: "Hello!")
        ).previewLayout(.sizeThatFits)

        Group {
            TextBoxView(text: .constant(""), showingErrorBadge: false, action: {})
            TextBoxView(text: .constant("Test"), showingErrorBadge: true, action: {})
        }.previewLayout(.sizeThatFits)
    }

    static var chatView: ChatView {
        let viewModel = ChatViewModel(
            chat: Chat(
                senderName: "User Name",
                senderId: UUID(),
                sendMessage: { _ in true }
            ),
            roster: Roster(
                currentParticipantId: UUID(),
                currentParticipantName: "User Name",
                avatarURL: { _ in nil }
            ),
            messages: [
                .init(title: "Chatbot", text: "User Name joined"),
                .init(title: "User Name", text: "Hello!"),
                .init(
                    title: "Participant",
                    text: """
                    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor
                    incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
                    quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo.
                    """
                )
            ]
        )
        return ChatView(viewModel: viewModel, onDismiss: {})
    }
}
