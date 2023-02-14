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

import Foundation
@testable import PexipInfinityClient

extension RegistrationToken {
    static func randomToken(
        updatedAt: Date = .init(),
        expires: TimeInterval = 120
    ) -> RegistrationToken {
        RegistrationToken(
            value: UUID().uuidString,
            updatedAt: updatedAt,
            registrationId: UUID().uuidString,
            directoryEnabled: Bool.random(),
            routeViaRegistrar: Bool.random(),
            expiresString: "\(expires)",
            version: Version(versionId: "10", pseudoVersion: "25010.0.0")
        )
    }
}
