import SwiftUI
import PexipInfinityClient
import PexipMedia
import PexipRTC
import PexipConference

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
        tokenError: TokenError,
        onComplete: @escaping PinChallengeViewModel.Complete
    ) -> PinChallengeView
}

// MARK: - Implementation

struct ViewFactory: ViewFactoryProtocol {
    private let apiClientFactory = InfinityClientFactory()
    private let conferenceFactory = ConferenceFactory()
    private let settings = Settings()

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
        tokenError: TokenError,
        onComplete: @escaping PinChallengeViewModel.Complete
    ) -> PinChallengeView {
        let viewModel = PinChallengeViewModel(
            tokenError: tokenError,
            tokenService: apiClientFactory
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
        token: Token,
        onComplete: @escaping () -> Void
    ) -> ConferenceView {
        let mediaConnectionFactory = WebRTCMediaConnectionFactory()
        let conference = conferenceFactory.conference(
            service: apiClientFactory.infinityService(),
            node: node,
            alias: alias,
            token: token
        )
        let mediaConnectionConfig = MediaConnectionConfig(
            signaling: conference.signaling,
            presentationInMain: false
        )
        let viewModel = ConferenceViewModel(
            conference: conference,
            mediaConnectionConfig: mediaConnectionConfig,
            mediaConnectionFactory: mediaConnectionFactory,
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
    #endif

    func settingsView() -> SettingsView {
        SettingsView(settings: settings)
    }
}

// MARK: - Environment

private struct ViewFactoryKey: EnvironmentKey {
    static let defaultValue = ViewFactory()
}

extension EnvironmentValues {
    var viewFactory: ViewFactory {
        get { self[ViewFactoryKey.self] }
        set { self[ViewFactoryKey.self] = newValue }
    }
}
