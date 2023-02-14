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

struct ParticipantsView: View {
    @ObservedObject var roster: Roster
    let onDismiss: () -> Void
    @Environment(\.verticalSizeClass) private var vSizeClass

    var body: some View {
        ModalView(
            onDismiss: onDismiss,
            colorScheme: .dark,
            content: {
                list.padding(.top, 20)
            }
        )
    }

    private var list: some View {
        List {
            if roster.participants.isEmpty {
                currentParticipantCell
            } else {
                ForEach(roster.participants) { participant in
                    ParticipantCell(
                        name: participant.displayName,
                        nameAbbreviation: Utils.abbreviation(
                            forName: participant.displayName
                        ),
                        avatarURL: roster.avatarURL(for: participant),
                        isMe: roster.isCurrentParticipant(participant)
                    )
                }
            }
        }
        .listStyle(.plain)
    }

    private var currentParticipantCell: some View {
        ParticipantCell(
            name: roster.currentParticipantName,
            nameAbbreviation: Utils.abbreviation(
                forName: roster.currentParticipantName
            ),
            avatarURL: roster.currentParticipantAvatarURL,
            isMe: true
        )
    }
}

// MARK: - Subviews

private struct ParticipantCell: View {
    let name: String
    let nameAbbreviation: String
    let avatarURL: URL?
    let isMe: Bool

    var body: some View {
        HStack {
            avatar
            Text(name).font(.body)
            Spacer()
            if isMe {
                Image(systemName: "person.fill")
                    .font(.footnote)
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 5)
        .multilineTextAlignment(.leading)
        #if os(iOS)
        .listRowSeparator(.hidden)
        #endif
        .listRowBackground(Color(.secondarySystemBackground))
        .preferredColorScheme(.dark)
    }

    private var avatar: some View {
        AsyncImage(url: avatarURL) { image in
            image.resizable()
        } placeholder: {
            Text(nameAbbreviation)
                .font(.footnote)
                .bold()
        }
        .frame(width: 40, height: 40)
        .background(Color.gray)
        .clipShape(Circle())
    }
}

// MARK: - Previews

struct ParticipantsView_Previews: PreviewProvider {
    private static let myId = UUID().uuidString

    static var previews: some View {
        ParticipantsView(
            roster: Roster(
                currentParticipantId: myId,
                currentParticipantName: "My User",
                participants: [
                    .stub(id: myId, displayName: "My User"),
                    .stub(displayName: "Test User 2"),
                    .stub(displayName: "Test User 3"),
                    .stub(displayName: "Test User 4"),
                    .stub(displayName: "Test User 5"),
                    .stub(displayName: "Test User 6"),
                    .stub(displayName: "Test User 7"),
                    .stub(displayName: "Test User 8"),
                    .stub(displayName: "Test User 9")
                ],
                avatarURL: { _ in nil }
            ),
            onDismiss: {}
        )

        ParticipantsView(
            roster: Roster(
                currentParticipantId: myId,
                currentParticipantName: "My User",
                participants: [],
                avatarURL: { _ in nil }
            ),
            onDismiss: {}
        )
    }
}

// MARK: - Stubs

private extension Participant {
    static func stub(id: String = UUID().uuidString, displayName: String) -> Participant {
        Participant(
            id: id,
            displayName: displayName,
            role: .guest,
            serviceType: .conference,
            callDirection: .inbound,
            hasMedia: true,
            isExternal: false,
            isStreamingConference: false,
            isVideoMuted: false,
            canReceivePresentation: true,
            isConnectionEncrypted: true,
            isDisconnectSupported: true,
            isFeccSupported: false,
            isAudioOnlyCall: false,
            isAudioMuted: false,
            isPresenting: false,
            isVideoCall: true,
            isMuteSupported: true,
            isTransferSupported: true
        )
    }
}
