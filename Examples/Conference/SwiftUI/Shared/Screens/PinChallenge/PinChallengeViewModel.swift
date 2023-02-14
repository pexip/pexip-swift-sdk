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

final class PinChallengeViewModel: ObservableObject {
    typealias Complete = (ConferenceToken) -> Void

    @Published var pin = ""
    @Published var isPinRequired = false
    @Published var errorMessage: String?
    @AppStorage("displayName") private(set) var displayName = "Guest"
    @MainActor var isValid: Bool {
        !pin.isEmpty || !isPinRequired
    }

    private let service: ConferenceService
    private let onComplete: Complete

    // MARK: - Init

    init(
        tokenError: ConferenceTokenError,
        service: ConferenceService,
        onComplete: @escaping Complete
    ) {
        self.service = service
        self.onComplete = onComplete
        handleTokenError(tokenError)
    }

    // MARK: - Actions

    @MainActor
    func submitPin() async {
        do {
            let fields = ConferenceTokenRequestFields(displayName: displayName)
            let token = try await service.requestToken(
                fields: fields,
                pin: pin
            )
            pin = ""
            onComplete(token)
        } catch let error as ConferenceTokenError {
            debugPrint(error)
            handleTokenError(error)
        } catch {
            debugPrint(error)
            errorMessage = error.localizedDescription
        }
    }

    private func handleTokenError(_ error: ConferenceTokenError) {
        switch error {
        case .invalidPin:
            errorMessage = "Incorrect PIN, please try again"
        case .pinRequired(let guestPinRequired):
            isPinRequired = guestPinRequired
        case .tokenDecodingFailed:
            errorMessage = "Something went wrong, please try again"
        case .conferenceExtensionRequired:
            errorMessage = "Virtual Reception conferences are not supported"
        case .ssoIdentityProviderRequired, .ssoIdentityProviderRedirect:
            errorMessage = "SSO is not supported"
        }
    }
}
