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

public struct FailureEvent: Hashable {
    public let id: UUID
    public let error: Error

    // MARK: - Init

    public init(
        id: UUID = UUID(),
        error: Error
    ) {
        self.id = id
        self.error = error
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(error.localizedDescription)
    }

    // MARK: - Equatable

    public static func == (lhs: FailureEvent, rhs: FailureEvent) -> Bool {
        lhs.id == rhs.id
            && lhs.error.localizedDescription == rhs.error.localizedDescription
    }
}
