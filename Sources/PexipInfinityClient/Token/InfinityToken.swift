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

import Foundation

public protocol InfinityToken {
    static var name: String { get }

    var value: String { get }
    var expires: TimeInterval { get }
    var updatedAt: Date { get }
    func updating(
        value: String,
        expires: String,
        updatedAt: Date
    ) -> Self
}

// MARK: - Helper functions

public extension InfinityToken {
    var expiresAt: Date {
        updatedAt.addingTimeInterval(expires)
    }

    var refreshDate: Date {
        let refreshInterval = expires / 2
        return updatedAt.addingTimeInterval(refreshInterval)
    }

    func isExpired(currentDate: Date = .init()) -> Bool {
        currentDate >= expiresAt
    }
}
