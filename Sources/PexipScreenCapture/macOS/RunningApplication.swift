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

/// An object that represents an app running on a device.
public protocol RunningApplication {
    /// The system process identifier of the app.
    var processID: pid_t { get }

    /// The unique bundle identifier of the app.
    var bundleIdentifier: String { get }

    /// The display name of the app.
    var applicationName: String { get }
}

// MARK: - Default implementations

public extension RunningApplication {
    func loadAppIcon(workspace: NSWorkspace = .shared) -> NSImage? {
        guard let path = workspace.urlForApplication(
            withBundleIdentifier: bundleIdentifier
        )?.path else {
            return nil
        }
        return workspace.icon(forFile: path)
    }
}

#endif
