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

final class AliasViewModel: ObservableObject {
    typealias Complete = (Output) -> Void

    struct Output {
        let alias: String
        let node: URL
        let token: Result<ConferenceToken, ConferenceTokenError>
    }

    var isValid: Bool { address != nil }
    @AppStorage("conferenceAlias") var text = ""
    @Published private(set) var errorMessage: String?
    @AppStorage("displayName") private var displayName = "Guest"

    private let nodeResolver: NodeResolver
    private let service: InfinityService
    private let onComplete: Complete
    private var address: ConferenceAddress? {
        ConferenceAddress(uri: text)
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

        guard let address else {
            showErrorMessage()
            return
        }

        var node: URL?

        do {
            node = try await service.resolveNodeURL(
                forHost: address.host,
                using: nodeResolver
            )
        } catch {
            debugPrint(error)
        }

        if let node = node {
            await checkPinRequirement(alias: address.alias, node: node)
        } else {
            showErrorMessage()
        }
    }

    @MainActor
    private func checkPinRequirement(alias: String, node: URL) async {
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
