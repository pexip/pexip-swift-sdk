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
import PexipInfinityClient

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
    let message: Chat.Message

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
        let chat = Chat(
            senderName: "User Name",
            senderId: UUID().uuidString,
            sendMessage: { _ in true }
        )
        let roster = Roster(
            currentParticipantId: UUID().uuidString,
            currentParticipantName: "User Name",
            avatarURL: { _ in nil }
        )
        let viewModel = ChatViewModel(
            store: ChatMessageStore(
                chat: chat,
                roster: roster,
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
        )
        return ChatView(viewModel: viewModel, onDismiss: {})
    }
}
