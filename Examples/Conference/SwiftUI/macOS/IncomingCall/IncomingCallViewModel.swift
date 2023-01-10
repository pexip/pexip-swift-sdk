import PexipMedia
import SwiftUI
import PexipInfinityClient

typealias IncomingCall = ConferenceDetails

final class IncomingCallViewModel: ObservableObject {
    typealias Accept = (IncomingCall) -> Void

    enum State {
        case calling
        case processing
        case error(String)
    }

    let details: IncomingCallEvent
    @Published private(set) var state = State.calling

    @AppStorage("displayName") private var displayName = "Guest"
    private let nodeResolver: NodeResolver
    private let service: InfinityService
    private let onAccept: Accept
    private let onDecline: () -> Void

    // MARK: - Init

    init(
        event: IncomingCallEvent,
        nodeResolver: NodeResolver,
        service: InfinityService,
        state: State = .calling,
        onAccept: @escaping Accept,
        onDecline: @escaping () -> Void
    ) {
        self.details = event
        self.nodeResolver = nodeResolver
        self.service = service
        self.onAccept = onAccept
        self.onDecline = onDecline
        self.state = state
    }

    // MARK: - Actions

    @MainActor
    func accept() async {
        guard
            let alias = ConferenceAlias(uri: details.conferenceAlias),
            let nodeURL = try? await service.resolveNodeURL(
                forHost: alias.host,
                using: nodeResolver
            )
        else {
            decline(withMessage: "Cannot join the call. Invalid address.")
            return
        }

        do {
            let displayName = self.displayName
            let fields = ConferenceTokenRequestFields(displayName: displayName)
            let token = try await service.node(url: nodeURL)
                .conference(alias: alias)
                .requestToken(fields: fields, incomingToken: details.token)
            onAccept(IncomingCall(node: nodeURL, alias: alias, token: token))
        } catch {
            debugPrint(error)
            decline(withMessage: "Cannot join the call. Invalid token.")
        }
    }

    func decline() {
        onDecline()
    }

    private func decline(withMessage message: String) {
        state = .error(message)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.onDecline()
        }
    }
}
