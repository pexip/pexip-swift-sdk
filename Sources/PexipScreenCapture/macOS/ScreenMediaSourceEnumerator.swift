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

#if os(macOS)

import CoreGraphics
#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

/// An object that retrieves the displays and windows for screen capture.
public protocol ScreenMediaSourceEnumerator {
    /// The url to the app's privacy settings.
    var permissionSettingsURL: URL? { get }

    /// Retrieves the displays for screen capture.
    func getShareableDisplays() async throws -> [Display]

    /// Retrieves the windows for screen capture.
    func getShareableWindows() async throws -> [Window]

    /// Retrieves all on screen windows, excluding desktop windows.
    func getAllOnScreenWindows() async throws -> [Window]
}

// MARK: - Default implementation

public extension ScreenMediaSourceEnumerator {
    var permissionSettingsURL: URL? {
        let prefix = "x-apple.systempreferences:com.apple.preference.security"
        let setting = "Privacy_ScreenRecording"
        return URL(string: "\(prefix)?\(setting)")
    }

    func getShareableWindows() async throws -> [Window] {
        try await getAllOnScreenWindows().filter {
            $0.windowLayer == 0
                && $0.title != nil
                && $0.title?.isEmpty == false
                && $0.application != nil
                && $0.application?.bundleIdentifier != Bundle.main.bundleIdentifier
                && $0.application?.bundleIdentifier.isEmpty == false
        }
    }
}

#endif
