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

#if os(macOS)

import CoreGraphics
#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

/**
 ScreenCaptureKit -based screen media source enumerator.
 https://developer.apple.com/documentation/screencapturekit
 */
@available(macOS 12.3, *)
struct NewScreenMediaSourceEnumerator<T: ShareableContent>: ScreenMediaSourceEnumerator {
    func getShareableDisplays() async throws -> [Display] {
        try await T.defaultSelection().displays
    }

    func getAllOnScreenWindows() async throws -> [Window] {
        try await T.defaultSelection().windows
    }
}

#endif
