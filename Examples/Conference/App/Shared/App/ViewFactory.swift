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
import PexipInfinityClient
import PexipMedia
import PexipRTC
import PexipScreenCapture

struct ViewFactory {
    let apiClientFactory: InfinityClientFactory
    let settings: Settings

    func displayNameView(
        onComplete: @escaping () -> Void
    ) -> DisplayNameView {
        let viewModel = DisplayNameViewModel(onComplete: onComplete)
        return DisplayNameView(viewModel: viewModel)
    }

    func aliasView(
        onComplete: @escaping AliasViewModel.Complete
    ) -> AliasView {
        let viewModel = AliasViewModel(
            nodeResolver: apiClientFactory.nodeResolver(dnssec: false),
            service: apiClientFactory.infinityService(),
            onComplete: onComplete
        )
        return AliasView(viewModel: viewModel)
    }

    func pinChallengeView(
        node: URL,
        alias: String,
        tokenError: ConferenceTokenError,
        onComplete: @escaping PinChallengeViewModel.Complete
    ) -> PinChallengeView {
        let viewModel = PinChallengeViewModel(
            tokenError: tokenError,
            service: apiClientFactory
                .infinityService()
                .node(url: node)
                .conference(alias: alias),
            onComplete: onComplete
        )
        return PinChallengeView(
            viewModel: viewModel
        )
    }

    func conferenceView(
        details: ConferenceDetails,
        preflight: Bool,
        onComplete: @escaping ConferenceViewModel.Complete
    ) -> ConferenceView {
        let mediaFactory = WebRTCMediaFactory()
        let conference = apiClientFactory.conference(
            node: details.node,
            alias: details.alias,
            token: details.token
        )
        let mediaConnectionConfig = MediaConnectionConfig(
            signaling: conference.signalingChannel,
            presentationInMain: false
        )
        let viewModel = ConferenceViewModel(
            conference: conference,
            conferenceConnector: ConferenceConnector(
                nodeResolver: apiClientFactory.nodeResolver(dnssec: false),
                service: apiClientFactory.infinityService()
            ),
            mediaConnectionConfig: mediaConnectionConfig,
            mediaFactory: mediaFactory,
            preflight: preflight,
            settings: settings,
            onComplete: onComplete
        )
        return ConferenceView(viewModel: viewModel)
    }

    func chatView(
        store: ChatMessageStore,
        onDismiss: @escaping () -> Void
    ) -> ChatView {
        let viewModel = ChatViewModel(store: store)
        return ChatView(viewModel: viewModel, onDismiss: onDismiss)
    }

    func participantsView(
        roster: Roster,
        onDismiss: @escaping () -> Void
    ) -> ParticipantsView {
        ParticipantsView(roster: roster, onDismiss: onDismiss)
    }

    #if os(macOS)

    func screenMediaSourcePicker(
        onShare: @escaping (ScreenMediaSource) -> Void,
        onCancel: @escaping () -> Void
    ) -> ScreenMediaSourcePicker {
        let viewModel = ScreenMediaSourcePickerModel(
            enumerator: ScreenMediaSource.createEnumerator(),
            onShare: onShare,
            onCancel: onCancel
        )
        return ScreenMediaSourcePicker(viewModel: viewModel)
    }

    func registrationView(
        service: RegistrationService
    ) -> RegistrationView {
        let viewModel = RegistrationViewModel(service: service)
        return RegistrationView(viewModel: viewModel)
    }

    func incomingCallView(
        event: IncomingCallEvent,
        onAccept: @escaping IncomingCallViewModel.Accept,
        onDecline: @escaping () -> Void
    ) -> IncomingCallView {
        let viewModel = IncomingCallViewModel(
            event: event,
            nodeResolver: apiClientFactory.nodeResolver(dnssec: false),
            service: apiClientFactory.infinityService(),
            onAccept: onAccept,
            onDecline: onDecline
        )
        return IncomingCallView(viewModel: viewModel)
    }

    #endif

    func settingsView() -> SettingsView {
        SettingsView(settings: settings)
    }
}
