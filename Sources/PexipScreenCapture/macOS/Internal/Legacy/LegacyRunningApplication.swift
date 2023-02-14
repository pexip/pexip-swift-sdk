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

import AppKit

struct LegacyRunningApplication: RunningApplication, Hashable {
    let processID: pid_t
    let bundleIdentifier: String
    let applicationName: String
}

// MARK: - Init

extension LegacyRunningApplication {
    init?(info: [CFString: Any], workspace: NSWorkspace = .shared) {
        guard let processID = info[kCGWindowOwnerPID] as? Int else {
            return nil
        }
        self.processID = pid_t(processID)

        guard let bundleIdentifier = workspace.runningApplications.first(where: {
            $0.processIdentifier == processID
        })?.bundleIdentifier else {
            return nil
        }
        self.bundleIdentifier = bundleIdentifier

        guard let name = info[kCGWindowOwnerName] as? String else {
            return nil
        }
        self.applicationName = name
    }
}

#endif
