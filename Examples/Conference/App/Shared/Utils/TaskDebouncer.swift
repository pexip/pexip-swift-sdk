//
// Copyright 2024 Pexip AS
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
import PexipCore

final class TaskDebouncer {
    private var task: Task<Void, Never>?

    init() {}

    func debounce(
        for duration: TimeInterval,
        block: @Sendable @escaping () async throws -> Void
    ) {
        task?.cancel()
        task = Task {
            do {
                let nanoseconds = UInt64(duration * 1_000_000_000)
                try await Task.sleep(nanoseconds: nanoseconds)
                try await block()
            } catch {}
        }
    }
}
