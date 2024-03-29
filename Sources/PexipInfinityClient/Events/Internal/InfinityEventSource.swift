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
import PexipCore

struct InfinityEventSource<Event>: CustomDebugStringConvertible {
    let name: String
    var minDelay: TimeInterval = 1
    var maxDelay: TimeInterval = 5
    var maxRetryCount: Int = 3
    var logger: Logger?
    let stream: () async throws -> AsyncThrowingStream<Event, Error>

    var debugDescription: String {
        "\(name) event source"
    }

    /// Event stream with retry mechanism.
    /// On error, there will be an attempt to reconnect
    /// until the connection is established or async stream is cancelled
    func events() -> AsyncThrowingStream<Event, Error> {
        AsyncThrowingStream { continuation in
            let logPrefix = String(reflecting: self)
            let task = Task {
                var attempts: Int = 0

                func operation() async throws {
                    for try await element in try await stream() {
                        attempts = 0
                        continuation.yield(element)
                    }
                }

                for _ in 0..<maxRetryCount {
                    do {
                        try await operation()
                    } catch let error as HTTPEventError {
                        logger?.warn("\(logPrefix): \(error)")

                        if [401, 403].contains(error.statusCode ?? 0) {
                            throw error
                        }

                        attempts += 1
                        let seconds = Swift.min(maxDelay, minDelay * Double(attempts))

                        logger?.info(
                            "\(logPrefix): Waiting \(seconds) seconds before reconnecting..."
                        )
                        try await Task.sleep(seconds: seconds)
                    }
                }

                try Task<Never, Never>.checkCancellation()
                try await operation()
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }

            Task {
                do {
                    try await task.value
                } catch {
                    logger?.error("\(name) event source error: failed to connect: \(error)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
