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

final class RegistrationViewModel: ObservableObject {
    @Published var alias = ""
    @Published var username: String
    @Published var password: String
    @Published var isRegistered = false
    @Published private(set) var errorMessage: String?

    private let service: RegistrationService

    var isValid: Bool {
        DeviceAddress(uri: alias) != nil && !username.isEmpty && !password.isEmpty
    }

    // MARK: - Init

    init(service: RegistrationService) {
        self.service = service
        self.alias = service.deviceAlias ?? ""
        self.username = service.username ?? ""
        self.password = service.password ?? ""
        self.isRegistered = service.isRegistered
    }

    // MARK: - Actions

    @MainActor
    func register() async {
        guard isValid else {
            errorMessage = "Required fields are missing"
            return
        }

        do {
            try await service.register(
                deviceAlias: alias,
                username: username,
                password: password
            )
            isRegistered = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func unregister() async {
        await service.unregister()
        isRegistered = false
    }
}
