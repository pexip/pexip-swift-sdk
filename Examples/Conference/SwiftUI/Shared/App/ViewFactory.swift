import SwiftUI
import PexipInfinityClient
import PexipMedia
import PexipRTC
import PexipScreenCapture

// MARK: - Protocol

protocol ViewFactoryProtocol {
    func displayNameView(
        onComplete: @escaping () -> Void
    ) -> DisplayNameView

    func aliasView(
        onComplete: @escaping AliasViewModel.Complete
    ) -> AliasView

    func pinChallengeView(
        node: URL,
        alias: ConferenceAlias,
        tokenError: ConferenceTokenError,
        onComplete: @escaping PinChallengeViewModel.Complete
    ) -> PinChallengeView
}

// MARK: - Implementation

struct ViewFactory: ViewFactoryProtocol {
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
        alias: ConferenceAlias,
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
        node: URL,
        alias: ConferenceAlias,
        token: ConferenceToken,
        onComplete: @escaping () -> Void
    ) -> ConferenceView {
        let mediaFactory = WebRTCMediaFactory()
        let conference = apiClientFactory.conference(
            node: node,
            alias: alias,
            token: token
        )
        let mediaConnectionConfig = MediaConnectionConfig(
            signaling: conference.signalingChannel,
            presentationInMain: false
        )
        let viewModel = ConferenceViewModel(
            conference: conference,
            mediaConnectionConfig: mediaConnectionConfig,
            mediaFactory: mediaFactory,
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
