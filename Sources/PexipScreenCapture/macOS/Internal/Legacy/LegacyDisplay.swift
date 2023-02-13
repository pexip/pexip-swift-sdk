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

struct LegacyDisplay: Display, Hashable {
    let displayID: CGDirectDisplayID
    let width: Int
    let height: Int
}

// MARK: - Init

extension LegacyDisplay {
    init?(
        displayID: CGDirectDisplayID,
        displayMode: (CGDirectDisplayID) -> DisplayMode? = {
            CGDisplayCopyDisplayMode($0)
        }
    ) {
        guard let displayMode = displayMode(displayID) else {
            return nil
        }

        self.displayID = displayID
        self.width = displayMode.width
        self.height = displayMode.height
    }
}

// MARK: - Helper types

protocol DisplayMode {
    var width: Int { get }
    var height: Int { get }
}

extension CGDisplayMode: DisplayMode {}

#endif
