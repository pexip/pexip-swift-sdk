import SwiftUI
import PexipInfinityClient
import PexipConference

final class AliasViewModel: ObservableObject {
    typealias Complete = (Output) -> Void

    struct Output {
        let alias: ConferenceAlias
        let node: URL
        let token: Result<ConferenceToken, ConferenceTokenError>
    }

    var isValid: Bool { alias != nil }
    @AppStorage("conferenceAlias") var text = ""
    @Published private(set) var errorMessage: String?
    @AppStorage("displayName") private var displayName = "Guest"

    private let nodeResolver: NodeResolver
    private let service: InfinityService
    private let onComplete: Complete
    private var alias: ConferenceAlias? {
        ConferenceAlias(uri: text)
    }

    // MARK: - Init

    init(
        nodeResolver: NodeResolver,
        service: InfinityService,
        onComplete: @escaping Complete
    ) {
        self.nodeResolver = nodeResolver
        self.service = service
        self.onComplete = onComplete
    }

    // MARK: - Actions

    @MainActor
    func search() async {
        func showErrorMessage() {
            errorMessage = "Looks like the address you typed in doesn't exist"
        }

        guard let alias = alias else {
            showErrorMessage()
            return
        }

        var node: URL?

        do {
            let nodes = try await nodeResolver.resolveNodes(for: alias.host)
            for url in nodes {
                if try await service.node(url: url).status() {
                    node = url
                    break
                }
            }
        } catch {
            debugPrint(error)
        }

        if let node = node {
            await checkPinRequirement(alias: alias, node: node)
        } else {
            showErrorMessage()
        }
    }

    @MainActor
    private func checkPinRequirement(alias: ConferenceAlias, node: URL) async {
        do {
            let conferenceService = service.node(url: node).conference(alias: alias)
            let fields = ConferenceTokenRequestFields(displayName: displayName)
            let token = try await conferenceService.requestToken(
                fields: fields,
                pin: nil
            )
            onComplete(.init(alias: alias, node: node, token: .success(token)))
        } catch let error as ConferenceTokenError {
            debugPrint(error)
            onComplete(.init(alias: alias, node: node, token: .failure(error)))
        } catch {
            debugPrint(error)
            errorMessage = error.localizedDescription
        }
    }
}
